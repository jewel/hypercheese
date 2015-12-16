@TagEditor = React.createClass
  getInitialState: ->
    expanded: false
    newLabel: @props.tag.label

  toggleSize: ->
    @setState
      expanded: !@state.expanded

  changeLabel: (e) ->
    @setState
      newLabel: e.target.value

  saveNewLabel: (e) ->
    e.preventDefault()
    @props.tag.label = @state.newLabel
    Store.forceUpdate()

  render: ->
    tag = @props.tag

    tagIconURL = "/data/resized/square/#{tag.icon}.jpg"
    if tag.icon == null
      tagIconURL = "/images/unknown-icon.png"

    classes = ['tag']
    classes.push 'expanded' if @state.expanded

    <div className={classes.join ' '}>
      <a className="expand-link" onClick={@toggleSize} href="javascript:void(0)">
        <img className="tag-icon" src={tagIconURL}/>
      </a>

      <br/>
      <form className="form-inline" onSubmit={@saveNewLabel}>
        {
          if @state.expanded && tag.item_count <= 0
            <div>
              <button className="btn btn-default" href="javascript:void(0)">
                <i className="fa fa-trash"/>
              </button>
            </div>
        }
        <input onChange={@changeLabel} type="text" className="form-control" value={@state.newLabel}/>
        <button type="submit" className="btn btn-primary">
          <i className="fa fa-save"/>
        </button>
      </form>
      <span className="desc">{" #{tag.label} (#{tag.item_count}) "}</span>
    </div>
