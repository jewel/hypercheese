@TagEditor = React.createClass
  getInitialState: ->
    parent_id = @props.tag.parent_id
    if parent_id
      parent = Store.state.tagsById[parent_id]
      label = parent.label if parent

    newLabel: @props.tag.label
    newParent: label

  changeLabel: (e) ->
    @setState
      newLabel: e.target.value

  changeParent: (e) ->
    @setState
      newParent: e.target.value

  changeAlias: (e) ->
    @setState
      newAlias: e.target.value

  saveChanges: (e) ->
    e.preventDefault()
    @props.tag.label = @state.newLabel

    parent_id = null
    parent_label = ''

    if @state.newParent
      for t in Store.state.tags
        if (t.alias || t.label).toLowerCase() == @state.newParent.toLowerCase()
          parent_id = t.id
          parent_label = (t.alias || t.label)

    @props.tag.parent_id = parent_id
    @props.tag.alias = @state.newAlias

    @setState
      newParent: parent_label

    Store.updateTag(@props.tag)

  deleteTag: (tag) ->
    if tag.item_count == null || tag.item_count <= 0
      Store.deleteTag(tag.id)

  render: ->
    tag = @props.tag

    choices = Store.loadIconChoices tag

    tagIconURL = "/data/resized/square/#{tag.icon}.jpg"
    if tag.icon == null
      tagIconURL = "/images/unknown-icon.png"

    <div className="container-fluid tag-editor-page">
      <a className="pull-right btn" href="javascript:void(0)" onClick={Store.navigateBack}><i className="fa fa-times"/></a>
      <h1>Tag Editor</h1>
      <div className="tag-frame">
        <img className="third" src={tagIconURL}/>
        <img className="second" src={tagIconURL}/>
        <img className="first" src={tagIconURL}/>
        <img className="second" src={tagIconURL}/>
        <img className="third" src={tagIconURL}/>
        <h2>&ldquo;{tag.alias || tag.label}&rdquo;</h2>
      </div>
      <ul>
        <li>used {tag.item_count.toLocaleString()} times</li>
        <li>search for <Link href={"/search/#{encodeURI(tag.alias || tag.label)}"}>{tag.alias || tag.label}</Link></li>
        <li>search for <Link href={"/search/#{encodeURI("only #{tag.alias || tag.label}")}"}>{"only #{tag.alias || tag.label}"}</Link></li>
        <li>search for <Link href={"/search/#{encodeURI("video #{tag.alias || tag.label}")}"}>{"video of #{tag.alias || tag.label}"}</Link></li>
      </ul>
      <form onSubmit={@saveChanges} style={width: "20em"}>
        <div className="form-group">
          <label htmlFor="label-input">Label</label>
          <input id="label-input" onChange={@changeLabel} type="text" className="form-control" value={@state.newLabel}/>
        </div>
        <div className="form-group">
          <label htmlFor="parent-input">Parent</label>
          <input id="parent-input" onChange={@changeParent} type="text" className="form-control" value={@state.newParent}/>
        </div>
        <div className="form-group">
          <label htmlFor="user-alias">Personal Alias</label>
          <input id="user-alias" onChange={@changeAlias} type="text" className="form-control" value={@state.newAlias}/>
          <p>This alias is used for faster tagging.  It is visible to you.</p>
        </div>
        <button type="submit" className="btn btn-primary">
          <i className="fa fa-save"/>
        </button>
        {
          if tag.item_count <= 0
            <div>
              <button className="btn btn-default" href="javascript:void(0)" onClick={@deleteTag.bind(@, tag)} type="button">
                <i className="fa fa-trash"/>
              </button>
            </div>
        }
      </form>

      <h3>Change Icon</h3>
      {
        if choices == null
          <i className="fa fa-spinner fa-spin"/>
        else
          <div className="icon-choice-list">
            {
              choices.map (itemId) ->
                url = "/data/resized/square/#{itemId}.jpg"
                updateIcon = ->
                  tag.icon = itemId
                  Store.updateTag(tag)

                <a key={itemId} href="javascript:void(0)" onClick={updateIcon}>
                  <img src={url}/>
                </a>
            }
          </div>
      }
    </div>
