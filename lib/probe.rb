require 'shellwords'
require 'json'

module Probe
  def self.se str
    Shellwords.shellescape str
  end

  def self.video path
    data = avprobe path

    info = {}
    data[:streams].each do |stream|
      next unless stream[:codec_type] == "video"
      info[:width] = stream[:width].to_i
      info[:height] = stream[:height].to_i
      info[:duration] = parse_duration stream[:duration]
      info[:codec] = stream[:codec_name]
      rate = stream[:r_frame_rate].split( '/' )
      info[:rate] = Rational(rate.first) / Rational(rate.second)

      break # use first video stream only
    end

    if (!info[:duration] || info[:duration] == 0.0) && data[:format] && data[:format][:duration]
      info[:duration] = parse_duration data[:format][:duration]
    end

    return info
  end

  def self.avprobe path
    # Probe the video dimensions to determine the ideal final size
    data = `ffprobe -v error -print_format json -show_format -show_streams #{se path}`
    raise "Couldn't probe #{path}" unless $? == 0

    JSON.parse data, symbolize_names: true
  end

  private
  def self.parse_duration val
    val == "N/A" ? nil : val.to_f
  end
end
