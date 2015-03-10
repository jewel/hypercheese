# Scale the given dimensions proportionally, so that the image isn't stretched
# # horizontally or vertically.  In other words, find the "best fit".
module Scaler
  def self.scale w, h, target_w, target_h
    ar = w.to_f / h
    target_ar = target_w.to_f / target_h
    if target_ar > ar
      return w.to_f * target_h / h, target_h.to_f
    else
      return target_w.to_f, h.to_f * target_w / w
    end
  end
end
