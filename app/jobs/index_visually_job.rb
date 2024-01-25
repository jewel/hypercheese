class IndexVisuallyJob < ApplicationJob
  FPS = 0.25

  def perform item_id
    item = Item.find item_id
    return if item.deleted
    return if item.aesthetics_score

    if item.photo?
      res = process_frame item.resized_path(:large)
      item.aesthetics_score = res[:score]
      store = EmbeddingStore.new "clip", 768
      store.put item.id, res[:embedding]
      item.save!
    elsif item.video?
      tmp = "/tmp/find-faces.#$$"
      FileUtils.rm_rf tmp
      Dir.mkdir tmp
      run "ffmpeg -v error -i #{se item.full_path} -vsync 1 -vf fps=#{FPS} -y #{se tmp}/out%06d.bmp"
      files = Dir.glob "#{tmp}/*.bmp"

      store = EmbeddingStore.new "video-clip", 768

      total_aesthetics_score = 0.0
      files.sort.each_with_index do |path, index|
        res = process_frame path
        total_aesthetics_score += res[:score]
        frame = ClipFrame.create!(
          item: item,
          aesthetics_score: res[:score],
          # FFMPEG seems to be taking the middle frame out of the group
          timestamp: (index + 0.5) / FPS,
        )
        store.put frame.id, res[:embedding]
      end
      # Store an average aesthetics score for the video.  This also lets us know
      # that the video was fully processed
      if files.size > 0
        item.aesthetics_score = total_aesthetics_score / files.size
      else
        item.aesthetics_score = 0.0
      end
      item.save!
    end
  end

  def process_frame path
    res = post_image 'http://face:7860/run/predict', path
    res[:data][0]
  end
end
