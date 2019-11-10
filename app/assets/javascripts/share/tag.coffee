@Tag = createReactClass
  render: ->
    tagIconURL = Store.resizedURL "square", @props.icon_id, @props.icon_code

    classes = ['tag']

    <div className={classes.join ' '}>
      <img title='' className="tag-icon" src={tagIconURL}/>
    </div>
