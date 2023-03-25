require 'rgeo/geo_json'

class RTreeNode
  attr_accessor :mbr, :shapes, :children, :id

  def initialize
    @@id ||= 0
    @@id += 1
    @id = @@id
    @mbr = nil
    @shapes = []
    @children = []
  end

  def to_s
    "<#{@id} #{@mbr.nil? ? "nil" : "MBR"}, #{@shapes.size} shapes, #{@children.size} children, #{mbr && area.round(3)}>"
  end

  def area
    (mbr[:xmax] - mbr[:xmin]) * (mbr[:ymax] - mbr[:ymin])
  end
end

class RTree
  attr_accessor :root

  def initialize
    @root = RTreeNode.new
  end

  def mbr_of_shape shape
    envelope = shape.geometry.envelope
    coords = envelope.exterior_ring.coordinates
    xmin = coords.map(&:first).min
    ymin = coords.map(&:last).min
    xmax = coords.map(&:first).max
    ymax = coords.map(&:last).max
    { xmin: xmin, ymin: ymin, xmax: xmax, ymax: ymax }
  end

  def merge_mbrs mbr1, mbr2
    if !mbr1 && !mbr2
      raise "two nil MBRs"
    elsif !mbr1
      return mbr2
    elsif !mbr2
      return mbr1
    end

    {
      xmin: [mbr1[:xmin], mbr2[:xmin]].min,
      ymin: [mbr1[:ymin], mbr2[:ymin]].min,
      xmax: [mbr1[:xmax], mbr2[:xmax]].max,
      ymax: [mbr1[:ymax], mbr2[:ymax]].max
    }
  end

  def insert(node, shape, max_children = 4)
    # puts "insert(#{node})"
    if node.shapes.size + node.children.size < max_children
      # puts " inserting into self"
      node.shapes << shape
      node.mbr = merge_mbrs node.mbr, mbr_of_shape(shape)
    elsif node.children.empty?
      # puts " self is full"
      node.shapes << shape
      node.mbr = merge_mbrs node.mbr, mbr_of_shape(shape)
      if node.shapes.size > max_children
        # puts " splitting"
        split_node node, max_children
      end
    else
      # puts " inserting into best child"
      best_child = choose_best_child(node, shape)
      # puts " chose #{best_child}"
      insert best_child, shape, max_children
      node.mbr = merge_mbrs node.mbr, mbr_of_shape(shape)
    end
  end

  def split_node(node, max_children)
    best_split = nil
    best_diff = Float::INFINITY

    node.shapes.combination(max_children / 2).each do |group1|
      group2 = node.shapes - group1
      mbr1 = group1.reduce(nil) { |acc, shape| merge_mbrs(acc, mbr_of_shape(shape)) }
      mbr2 = group2.reduce(nil) { |acc, shape| merge_mbrs(acc, mbr_of_shape(shape)) }
      diff = area(merge_mbrs(mbr1, mbr2)) - area(mbr1) - area(mbr2)

      if diff < best_diff
        best_diff = diff
        best_split = [group1, group2]
      end
    end

    node.shapes = []
    best_split.each do |group|
      # puts "  creating new node with #{group.size} shapes"
      child = RTreeNode.new
      group.each { |shape| insert(child, shape, max_children) }
      node.children << child
      # puts "  created #{child}"
    end
  end


  def choose_best_child node, shape
    node.children.min_by do |child|
      # puts " looking at #{child}"
      mbr = merge_mbrs child.mbr, mbr_of_shape(shape)
      area_increase = area(mbr) - area(child.mbr)
      [area_increase, area(child.mbr)]
    end
  end

  def area mbr
    return 0.0 unless mbr
    (mbr[:xmax] - mbr[:xmin]) * (mbr[:ymax] - mbr[:ymin])
  end

  def point_in_mbr point, mbr
    point.x >= mbr[:xmin] && point.x <= mbr[:xmax] && point.y >= mbr[:ymin] && point.y <= mbr[:ymax]
  end

  def query node, point
    return [] unless node
    return [] if node.mbr && !point_in_mbr(point, node.mbr)

    shapes_found = node.shapes.select { |shape| shape.geometry.contains?(point) }
    node.children.each do |child|
      shapes_found += query(child, point)
    end

    shapes_found
  end
end
