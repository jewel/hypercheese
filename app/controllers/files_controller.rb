class FilesController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_before_action :verify_approval!

  def manifest
    files = JSON.parse request.body.read, symbolize_names: true
    res = []
    files.each do |file|
      res.push({
        path: file[:path]
      })
    end
    render json: res
  end

  rescue_from StandardError, with: :handle_error

  def hashes
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
    data = request.body.read
    path = request.headers['X-Path']
    Rails.logger.info "Got #{data.size} bytes as #{path}"
    head :ok
  end

  def handle_error exception
    backtrace_summary = exception.backtrace.take(3).join("\n")

    error_message = "<#{exception.class}>: #{exception.message}\n#{backtrace_summary}\n"
    render plain: error_message, status: :internal_server_error
  end
end
