require 'shellwords'

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  def run cmd
    puts "[job] " + cmd
    system( cmd ) or raise "Could not run #{cmd}"
    $? == 0 or raise "Failed command"
  end

  def se str
    Shellwords.shellescape str.to_s
  end

  def post_image url, image_path
    enc = "data:image/jpeg;base64," + Base64.encode64(File.binread(image_path))

    # FIXME standardize key name
    if url =~ /:5000/
      key = :img
    else
      key = :data
    end

    # FIXME standardize array

    if url =~ /represent/
      val = enc
    else
      val = [enc]
    end

    res = HTTParty.post(url, body: { key => val }.to_json, headers: { 'Content-Type' => 'application/json' })

    if res.code != 200
      raise "Bad response code for #{url.inspect}: #{res.code}"
    end

    JSON.parse res.body, symbolize_names: true
  end
end
