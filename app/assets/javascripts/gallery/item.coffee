@Item = React.createClass
  render: ->
    item = @props.item

    imageStyle =
      width: "#{@props.imageWidth}px"
      height: "#{@props.imageHeight}px"

    bgColor = if item.isSelected
      "blue"
    else
      item.bgcolor

    bgStyle =
      "backgroundColor": bgColor

    if item.id?
      squareImage = "/data/resized/square/#{item.id}.jpg"
    else
      squareImage = "/images/loading.png"

    selected = if item.isSelected then 'selected' else ''
    <div className="item" style={bgStyle} onClick={@props.onClick} key="item_#{item.id || Math.random()}">
      <img className="thumb" style={imageStyle} src={squareImage}/>
      <div className="#{selected}" ></div>
    </div>
