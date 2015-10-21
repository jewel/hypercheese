@Item = React.createClass
  onClick: ->
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

    classes = ["thumb"]
    classes.push 'is-selected' if item.get('isSelected')

    <div className="item" style={bgStyle} onClick={@onClick} key="item_#{item.get('id') || Math.random()}">
      <img className={classes.join ' '} style={imageStyle} src={squareImage}/>
      {
        if item.get('hasComments')
          <img className="comments" src="/images/comment.png"/>
      }
      <div className="mini-tag-icons">
        {
          item.get('tags').map (tag) ->
            <img key={tag.get('id')} src={tag.get('iconUrl')}/>
        }
      </div>
    </div>
