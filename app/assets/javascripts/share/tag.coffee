@Tag = createReactClass
  render: ->
    tagIconURL = "/data/resized/square/#{@props.icon}.jpg"
    if @props.icon == null
      tagIconURL = "/images/unknown-icon.png"

    classes = ['tag']

    <div className={classes.join ' '}>
      <img title='' className="tag-icon" src={tagIconURL}/>
    </div>
