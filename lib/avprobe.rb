require 'shellwords'
module Probe
  def self.se str
    Shellwords.shellescape str
  end

  def self.video path
    data = avprobe path

    info = {}
    data[:STREAM].each do |stream|
      next unless stream[:codec_type] == "video"
      info[:width] = stream[:width].to_i
      info[:height] = stream[:height].to_i
      info[:duration] = parse_duration stream[:duration]
      info[:codec] = stream[:codec_name]

      break # use first video stream only
    end

    return info
  end

  def self.avprobe path
    # Probe the video dimensions to determine the ideal final size
    if avprobe_version.first > 9
      data = `avprobe -of old -v error -show_format -show_streams #{se path}`
    else
      data = `avprobe -v error -show_format -show_streams #{se path}`
    end
    raise "Couldn't probe #{path}" unless $? == 0

    parse_avprobe data
  end

  private
  def self.parse_duration val
    val == "N/A" ? nil : val.to_f
  end

  def self.avprobe_version
    return @avprobe_version if @avprobe_version
    version = `avprobe -v error -version | head -n 1`
    version =~ /\Aavprobe (\d+)/ or raise "Can't parse avprobe version: #{version.inspect}"
    major = $1.to_i
    minor = $2.to_i
    @avprobe_version = [major, minor]
  end

  def self.parse_avprobe data
    res = {}
    section = nil
    current = {}
    data.split( "\n" ).each do |line|
      if line =~ /^\[(\w+)\]$/
        section = $1.to_sym
        current = {}
        res[section] ||= []
        res[section] << current
      end
      next unless section
      next unless line =~ /^(\w+)=(.*)$/
      current[$1.to_sym] = $2
    end
    res
  end
end
