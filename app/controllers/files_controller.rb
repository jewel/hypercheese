class FilesController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_before_action :verify_approval!

  rescue_from StandardError, with: :handle_error

  def authenticate
    info = JSON.parse request.body.read, symbolize_names: true
    user = User.find_by username: info[:username]
    unless user&.valid_password?(info[:password])
      return render plain: "Invalid username or password", status: :unauthorized
    end
    payload = { user_id: user.id, device: SecureRandom.uuid }
    token = JWT.encode payload, Rails.application.secrets.secret_key_base
    render json: { token: token }
  end

  def manifest
    auth!
    files = JSON.parse request.body.read, symbolize_names: true
    res = []
    files.each do |file|
      dest = dest_path file[:path]
      if dest.exist? && dest.mtime.to_f.round == (file[:mtime].to_f / 1000).round && dest.size == file[:size]
        next
      end
      res.push({
        path: file[:path]
      })
    end
    render json: res
  end

  # Since we're not indexing hashes on the server side yet, this is just a
  # no-op.  It will take their device a little while to hash the files but it's
  # only going to be rare that there are duplicates.
  def hashes
    auth!
    files = JSON.parse request.body.read, symbolize_names: true
    res = []
    files.each do |file|
      res.push({
        path: file[:path]
      })
    end
    render json: res
  end

  def upload
    auth!
    path = request.headers['X-Path']
    mtime = request.headers['X-MTime'].to_f / 1000
    dest = dest_path path
    FileUtils.mkdir_p File.dirname dest
    temp = "#{dest}.#$$.tmp"
    File.open temp, 'wb' do |f|
      IO.copy_stream request.body, f
    end
    File.utime mtime, mtime, temp.to_s
    File.rename temp, dest.to_s
    head :ok
  end

  private

  def auth!
    if request.headers['X-API-Version'] != "1.0"
      raise "Invalid API Version"
    end
    token = request.headers['Authorization']&.split(' ')&.last
    payload = JWT.decode(token, Rails.application.secrets.secret_key_base).first
    @user = User.find payload["user_id"]
    @device = payload["device"]
    raise "Authorization problem" unless @user && @device.present?
  end

  def handle_error exception
    backtrace_summary = exception.backtrace.take(3).join("\n")

    error_message = "<#{exception.class}>: #{exception.message}\n#{backtrace_summary}\n"

    Rails.logger.error error_message

    render plain: error_message, status: :internal_server_error
  end

  def base_dir
    Rails.root + "storage/uploads" + @user.id.to_s + @device
  end

  def dest_path remote_path
    path = remote_path.sub(%r{\A/}, '')
    dest = (base_dir + path).cleanpath
    unless dest.to_s.start_with? base_dir.to_s
      raise "Path is outside of expected base directory"
    end
    dest
  end
end
