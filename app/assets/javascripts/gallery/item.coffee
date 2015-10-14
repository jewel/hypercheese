@Item = React.createClass
  onClick: ->
    console.log 'click on ', @props.item
    @props.item.set 'isSelected', !@props.item.get('isSelected')

  render: ->
    item = @props.item

    imageStyle =
      width: "#{@props.imageWidth}px"
      height: "#{@props.imageHeight}px"

    bgColor = if item.get('isSelected')
      "blue"
    else
      item.get('bgcolor')

    bgStyle =
      "backgroundColor": bgColor

    if item.id?
      squareImage = "/data/resized/square/#{item.get('id')}.jpg"
    else
      squareImage = "/images/loading.png"

    selected = if item.get('isSelected') then 'selected' else ''
    <div className="item" style={bgStyle} onClick={@onClick} key="item_#{item.get('id') || Math.random()}">
      <img className="thumb" style={imageStyle} src={squareImage}/>
      <div className="#{selected}" ></div>
    </div>
