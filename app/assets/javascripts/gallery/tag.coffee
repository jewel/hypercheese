@Tag = createReactClass
  render: ->
    tag = @props.tag
    tagIconURL = Store.resizedURL "square", tag.icon_id, tag.icon_code

    classes = ['tag']
    classes.push 'selected' if @props.selected

    <div className={classes.join ' '} onClick={@props.onClick}>
      <img title={tag.alias || tag.label} className="tag-icon" src={tagIconURL}/>
      {
        if @props.label
          <div>{tag.alias || tag.label}</div>
      }
      {@props.children}
    </div>
