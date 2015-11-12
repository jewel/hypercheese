@Tag = React.createClass
  render: ->
    tag = @props.tag
    tagIconURL = "/data/resized/square/#{tag.icon}.jpg"

    <div className="tag">
      <img title={tag.label} className="tag-icon" src={tagIconURL}/>
      {
        if @props.label
          <div>{tag.label}</div>
      }
      {@props.children}
    </div>
