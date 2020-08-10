module CollapseRange
  # Searches with lots of IDs are too long for GET URIs.  Collapse ranges,
  # since imported items will usually be in order.
  def self.collapse nums
    groups = []
    cur_seq = []
    groups << cur_seq
    nums.each do |num|
      if cur_seq.last && cur_seq.last + 1 == num
        cur_seq << num
      elsif cur_seq.empty?
        cur_seq << num
      else
        cur_seq = [num]
        groups << cur_seq
      end
    end

    groups.map! do |seq|
      if seq.size == 1
        "#{seq.first}"
      elsif seq.size == 2
        "#{seq.first},#{seq.last}"
      else
        "#{seq.first}-#{seq.last}"
      end
    end

    groups.join ","
  end
end
