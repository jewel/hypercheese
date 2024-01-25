class GenerateExplodedVideoJob < ApplicationJob
  def perform item_id
    item = Item.find item_id
    return if item.deleted

    dest = item.resized_path :exploded
    return if File.exists? dest

    tmp = "/tmp/make-exploded.#$$.#{rand 1_000_000}"

    Dir.mkdir tmp
    info = Probe.video item.full_path
    target_w, target_h = [1920, 1080]
    if info[:width] < info[:height]
      target_w, target_h = [target_h, target_w]
    end

    total_w, total_h = Scaler.scale info[:width], info[:height], target_w, target_h

    # Have a frame about every three seconds
    target_frame_count = info[:duration] / 3

    # But round to the nearest square
    grid_w = Math.sqrt(target_frame_count).round
    grid_w = 1 if grid_w < 1
    grid_h = grid_w

    thumb_w = (total_w / grid_w).round
    thumb_h = (total_h / grid_h).round

    total = grid_w * grid_h
    gap = info[:duration] / total
    warn "gap will be #{gap.inspect}"

    run "ffmpeg -v error -i #{se item.full_path} -vsync 1 -vf fps=#{1.0/gap} -vframes #{total} -s #{thumb_w}x#{thumb_h} -y #{se tmp}/out%06d.bmp"

    run "montage #{se tmp}/*.bmp -geometry #{thumb_w}x#{thumb_h}+0+0 -tile #{grid_w}x#{grid_h} #{se tmp}/grid.jpg"
    FileUtils.mkdir_p File.dirname( dest )
    FileUtils.move "#{tmp}/grid.jpg", dest
    run "rm -r #{se tmp}"
  end
end
