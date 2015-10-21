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

    maxFit = 6
    tagCount = item.get('tags.length')
    hasComments = item.get('hasComments')
    numberToShow = maxFit
    numberToShow-- if hasComments
    if tagCount > numberToShow
      numberToShow--
    firstTags = item.get('tags').slice(0,numberToShow)
    extraTags = tagCount - firstTags.length

    <div className="item" style={bgStyle} onClick={@onClick} key="item_#{item.get('id') || Math.random()}">
      <img className={classes.join ' '} style={imageStyle} src={squareImage}/>
      <div className="tagbox">
        {
          if hasComments
            <img src="/images/comment.png"/>
        }
        {
          firstTags.map (tag) ->
            <img className="tag-icon" key={tag.get('id')} src={tag.get('iconUrl')}/>
        }
        {
          if extraTags > 0
            <div className="extra-tags">{'+' + extraTags}</div>
        }
      </div>
    </div>
