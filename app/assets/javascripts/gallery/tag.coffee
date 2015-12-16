@Tag = React.createClass
  render: ->
    tag = @props.tag
    tagIconURL = "/data/resized/square/#{tag.icon}.jpg"
    if tag.icon == null
      tagIconURL = "/images/unknown-icon.png"

    classes = ['tag-icon']
    classes.push 'selected' if @props.selected

    <div className="tag" onClick=@props.onClick>
      <img title={tag.label} className={classes.join ' '} src={tagIconURL}/>
      {
        if @props.label
          <div>{tag.label}</div>
      }
      {@props.children}
    </div>
