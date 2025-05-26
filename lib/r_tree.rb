require 'rgeo/geo_json'

# Wrapper around shapes because they use too much memory in aggregate, and we
# only need one or two of them anyway
class ShapeShifter
  @@next_id = 0

  attr_accessor :id, :rect
  def initialize id, rect
    @id = id
    @rect = rect
  end

  def rgeo_shape
    RGeo::GeoJSON.decode File.binread "db/geo.index/#{id}"
  end

  def self.store rgeo_shape
    @@next_id += 1
    id = @@next_id
    File.binwrite "db/geo.index/#{id}", RGeo::GeoJSON.encode(rgeo_shape).to_json

    rect = Rect.from_shape rgeo_shape

    self.new id, rect
  end
end

class Rect
  attr_accessor :xmin, :xmax, :ymin, :ymax

  def self.from_shape rgeo_shape
    envelope = rgeo_shape.geometry.envelope
    coords = envelope.exterior_ring.coordinates
    rect = Rect.new
    rect.xmin = coords.map(&:first).min
    rect.ymin = coords.map(&:last).min
    rect.xmax = coords.map(&:first).max
    rect.ymax = coords.map(&:last).max
    rect
  end

  def area
    (xmax - xmin) * (ymax - ymin)
  end

  def + other
    res = Rect.new
    res.xmin = [xmin, other.xmin].min
    res.xmax = [xmax, other.xmax].max
    res.ymin = [ymin, other.ymin].min
    res.ymax = [ymax, other.ymax].max
    res
  end

  def contains? point
    point.x >= xmin && point.x <= xmax && point.y >= ymin && point.y <= ymax
  end
end

class RTreeNode
  attr_accessor :rect, :shapes, :children

  def initialize
    @rect = nil
    @shapes = []
    @children = []
  end

  def to_s
    "<#{@shapes.join '-'} shapes, #{rect && area.round(3)}>"
  end

  def area
    return 0.0 unless @rect
    @rect.area
  end
end

class RTree
  attr_accessor :root

  def initialize root
    @root = root
    @max_children = 4
  end

  def insert node, shape
    # puts "insert(#{node})"
    leaf = node.children.empty?

    if node.rect
      node.rect += shape.rect
    else
      node.rect = shape.rect
    end

    if leaf
      # puts " inserting into self"
      if node.shapes.size == @max_children
        # puts " splitting"
        split_node node
        # retry
        insert node, shape
      else
        node.shapes << shape
      end
    else
      # branch

      # puts " inserting into best child"
      best_child = choose_best_child node, shape

      # puts " chose #{best_child}"
      insert best_child, shape
    end
  end

  # split a leaf node into branch nodes
  def split_node node
    node.shapes.each do |shape|
      child = RTreeNode.new
      insert child, shape
      node.children << child
    end
    node.shapes = []
  end

  # choose whichever child would grow the least if shape were added to it
  # if there's a tie then choose the smallest shape
  def choose_best_child node, shape
    node.children.sort_by do |child|
      # puts " looking at #{child}"
      rect = child.rect + shape.rect
      [rect.area - child.rect.area, child.rect.area]
    end.first
  end

  def query node, point
    return [] unless node
    return [] unless node.rect.contains?(point)

    shapes_found = []
    node.shapes.each do |shape|
      next unless shape.rect.contains?(point)
      next unless shape.rgeo_shape.geometry.contains?(point)
      shapes_found << shape.rgeo_shape
    end

    node.children.each do |child|
      shapes_found += query(child, point)
    end

    shapes_found
  end
end
