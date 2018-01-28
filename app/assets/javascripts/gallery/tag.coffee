@Tag = React.createClass
  render: ->
    tag = @props.tag
    tagIconURL = "/data/resized/square/#{tag.icon}.jpg"
    if tag.icon == null
      tagIconURL = "/images/unknown-icon.png"

    classes = ['tag']
    classes.push 'selected' if @props.selected

    <div className={classes.join ' '} onClick=@props.onClick>
      <img title={tag.alias || tag.label} className="tag-icon" src={tagIconURL}/>
      {
        if @props.label
          <div>{tag.alias || tag.label}</div>
      }
      {@props.children}
    </div>
