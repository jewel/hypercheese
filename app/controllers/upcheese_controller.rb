require 'digest/md5'
require 'import'
require 'fileutils'

class UpcheeseController < ApplicationController
  def check
    md5s = request.body.read.split "\n"
    items = Item.where(md5: md5s).select :md5
    uploaded_md5s = items.map { |i| i.md5 }
    render text: uploaded_md5s.join( "\n" )
  end

  def upload
    data = request.body.read
    md5 = Digest::MD5.hexdigest(data)
    raise "MD5s don't match" unless md5 == params[:md5]
    user_path = params[:path]
    user_path.gsub! /\/\.\.\//, '/'
    user_path.gsub! /\A\//, ''
    path = "#{Rails.root}/originals/uploads/#{user_path}"

    FileUtils.mkdir_p File.dirname( path )
    File.binwrite path, data
    File.utime params[:mtime].to_i, params[:mtime].to_i, path
    Import.by_path(path)

    render text: 'hypercheese received file successfully'
  end
end
