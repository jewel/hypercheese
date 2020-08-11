module CollapseRange
  # Searches with lots of IDs are too long for GET URIs.  Collapse ranges,
  # since imported items will usually be in order.
  def self.collapse nums
    nums.sort!
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
      else
        # Shorthand (1000-10 means 1000-1010)
        last = ""
        common = common_prefix(seq.first.to_s, seq.last.to_s)
        "#{seq.first}-#{seq.last.to_s.delete_prefix(common)}"
      end
    end

    groups.join ","
  end

  private
  def self.common_prefix a, b
    return "" if a.size != b.size
    common = ""
    i = 0
    while i < a.size
      break if a[i] != b[i]
      common += a[i]
      i += 1
    end
    common
  end
end
