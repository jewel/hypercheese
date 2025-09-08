module CollapseRange
  # Searches with lots of IDs are too long for GET URIs.  Collapse ranges,
  # since imported items will usually be in order.
  def self.collapse nums
    nums = nums.sort

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

    prev_seq = nil
    groups.map! do |seq|
      first = seq.first
      # compress common prefix with '
      if prev_seq
        common = common_prefix prev_seq.last.to_s, first.to_s
        if common.size > 1
          first = "'#{first.to_s.delete_prefix(common)}"
        end
      end
      prev_seq = seq

      if seq.size == 1
        "#{first}"
      else
        # Shorthand (1000-10 means 1000-1010)
        common = common_prefix seq.first.to_s, seq.last.to_s
        "#{first}-#{seq.last.to_s.delete_prefix(common)}"
      end
    end

    groups.join ","
  end

  def self.expand str
    groups = str.split ","
    ids = []
    prev = nil
    groups.each do |seq|
      start, finish = seq.split '-'

      # Expand partial-digit shorthand for start
      # Example: 1000,'2 as an encoding for 1000,1002

      if prev && start.start_with?("'")
        start = prev[0..-start.size] + start[1..]
      end

      finish ||= start

      # Check for partial digit shorthand for finish
      # Example: 1000-2 as an encoding for 1000,1001,1002
      if finish.to_i < start.to_i
        finish = start[0...-finish.size] + finish
      end

      prev = finish

      ids.concat (start.to_i..finish.to_i).to_a
    end
    ids
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
