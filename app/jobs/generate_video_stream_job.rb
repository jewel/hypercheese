class GenerateVideoStreamJob < ApplicationJob
  def perform item_id
    item = Item.find item_id
    return if item.deleted

    path = item.full_path

    dest = item.video_stream_path
    return if File.exists? dest

    FileUtils.mkdir_p File.dirname( dest )
    tmp = "#{dest}.tmp"

    info = Probe.video path
    height = [720, info[:height]].min
    rate = [60, info[:rate]].min

    run "ffmpeg -v error -i #{se path} -b:a 128k -ar 48000 -strict experimental -vf scale=-2:#{se height} -r #{se rate} -acodec aac -crf 23 -vcodec libx264 -pix_fmt yuv420p -f mp4 -y #{se tmp}"

    File.chmod 0644, tmp
    File.rename tmp, dest
  end
end
