class FilesController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_before_action :verify_approval!

  before_action :require_auth!, except: :authenticate

  rescue_from StandardError, with: :handle_error

  require 'open3'

  # File upload is designed to be lightweight on the client side, with no
  # database required on the client side to track what has been uploaded so
  # far.  Instead, the server will keep track of what the client has previously
  # uploaded.  Just like rsync, we'll assume files are the same if they have
  # the same mtime and filesize and pathname.
  #
  # Upload is done in four steps:
  #
  # Step one: POST to /files/auth with a username and password.  This only
  # needs to happen once per device, a device token will be memorized by the
  # client for future uploads.
  #
  # Step two: POST to /files/manifest.  A JSON array of files is POSTed,
  # representing the entirety of what is on the remote computer.  The server
  # responds with the paths of the files that should be hashed.
  #
  # Step three: POST to /files/hashes.  The client sends the manifest again, but
  # this time with the SHA256 hash of the file contents.  The server will
  # respond with the paths of the files that should be uploaded.
  #
  # Step four: PUT to /files/upload.  Each file from step three is sent one at a
  # time, in a separate PUT request.

  def authenticate
    info = JSON.parse request.body.read, symbolize_names: true
    if current_user
      user = current_user
    else
      user = User.find_by username: info[:username]
      unless user&.valid_password?(info[:password])
        return render plain: "Invalid username or password", status: :unauthorized
      end
    end
    device = Device.create!(
      user_id: user.id,
      uuid: SecureRandom.uuid,
      nickname: info[:nickname],
      os: info[:os],
      client_software: info[:client_software],
      client_version: info[:client_version]
    )
    payload = { user_id: user.id, device: device.uuid }
    token = JWT.encode payload, Rails.application.credentials.secret_key_base
    render json: { token: token }
  end

  def manifest
    files = JSON.parse request.body.read, symbolize_names: true
    paths = files.map { _1[:path] }
    blobs = CheeseBlob.where path: paths, user: @user, device: @device
    blobs = blobs.index_by &:path

    @device.update!(
      last_manifest_at: Time.current,
      os: params[:os],
      nickname: params[:nickname],
      client_version: params[:client_version]
    )

    res = []
    files.each do |file|
      blob = blobs[file[:path]]
      same_mtime = (blob&.mtime.to_f * 1000).round == file[:mtime]
      same_size = blob&.size == file[:size]
      next if same_mtime && same_size
      res.push({ path: file[:path] })
    end

    render json: res.to_json
  end

  def hashes
    files = JSON.parse request.body.read, symbolize_names: true
    sha256s = files.map { _1[:sha256].downcase }
    existing_blobs = CheeseBlob.where sha256: sha256s
    existing_blobs_by_sha = existing_blobs.index_by &:sha256

    res = []
    files.each do |file|
      existing_blob = existing_blobs_by_sha[file[:sha256]]

      if existing_blob
        CheeseBlob.create!(
          user: @user,
          device: @device,
          path: file[:path],
          sha256: file[:sha256].downcase,
          size: file[:size],
          mtime: Time.at(file[:mtime].to_f / 1000),
        )
      else
        res.push({
          path: file[:path]
        })
      end
    end
    render json: res.to_json
  end

  def upload
    path = request.headers['X-Path']
    mtime = request.headers['X-MTime'].to_f / 1000
    sha256 = request.headers['X-SHA256'].downcase
    size = request.headers['X-Size'].to_i

    data = request.body.read
    if data.size != size
      return render plain: "Size mismatch (header: #{size}, body: #{data.size})", status: :bad_request
    end

    if Digest::SHA256.hexdigest(data) != sha256
      return render plain: "SHA256 mismatch (header: #{sha256}, body: #{Digest::SHA256.hexdigest(data)})", status: :bad_request
    end

    # Get content type using file -bi
    Tempfile.open(['upload', '']) do |tempfile|
      tempfile.binmode
      tempfile.write data
      content_type, status = Open3.capture2 'file', '-bi', tempfile.path
      content_type = content_type.strip
    end

    s3_key = object_key sha256
    Bucket.put_object(
      key: s3_key,
      body: data,
      content_type: content_type
    )

    blob = CheeseBlob.create!(
      user: @user,
      device: @device,
      path: path,
      sha256: sha256,
      size: size,
      mtime: Time.at(mtime),
    )

    @device.update! last_upload_at: Time.current

    source = Source.find_by device: @device
    if source
      Import.by_blob blob
    end

    head :ok
  end

  private

  def require_auth!
    if request.headers['X-API-Version'] != "1.0"
      raise "Invalid API Version"
    end
    token = request.headers['Authorization']&.split(' ')&.last
    payload = JWT.decode(token, Rails.application.credentials.secret_key_base).first
    @user = User.find payload["user_id"]
    @device = Device.find_by_uuid payload["device"]
    raise "Authorization problem" unless @user && @device
  end

  def handle_error exception
    backtrace_summary = exception.backtrace.take(3).join("\n")

    error_message = "<#{exception.class}>: #{exception.message}\n#{backtrace_summary}\n"

    Rails.logger.error error_message

    render plain: error_message, status: :internal_server_error
  end

  def object_key sha256
    "storage/#{sha256}"
  end
end
