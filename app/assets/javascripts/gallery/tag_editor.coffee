component 'TagEditor', ({tag}) ->
  [newLabel, setNewLabel] = useState tag?.label || ''
  [newParent, setNewParent] = useState ->
    parent_id = tag?.parent_id
    if parent_id
      parent = Store.state.tagsById[parent_id]
      return parent?.label || ''
    return ''
  [newAlias, setNewAlias] = useState tag?.alias || ""

  changeLabel = (e) ->
    setNewLabel e.target.value

  changeParent = (e) ->
    setNewParent e.target.value

  changeAlias = (e) ->
    setNewAlias e.target.value

  saveChanges = (e) ->
    e.preventDefault()
    tag.label = newLabel

    parent_id = null
    parent_label = ''

    if newParent
      for t in Store.state.tags
        if (t.alias || t.label).toLowerCase() == newParent.toLowerCase()
          parent_id = t.id
          parent_label = (t.alias || t.label)

    tag.parent_id = parent_id
    tag.alias = newAlias

    setNewParent parent_label

    Store.updateTag tag

  deleteTag = (tag) ->
    if tag.item_count == null || tag.item_count <= 0
      Store.deleteTag tag.id

  choices = Store.loadIconChoices tag

  tagIconURL = Store.resizedURL "square", tag.icon_id, tag.icon_code

  <div className="container-fluid tag-editor-page">
    <button className="pull-right btn" onClick={Store.navigateBack}><i className="fa fa-times"/></button>
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
    <Writer>
      <form onSubmit={saveChanges} style={width: "20em"}>
        <div className="form-group">
          <label htmlFor="label-input">Label</label>
          <input id="label-input" onChange={changeLabel} type="text" className="form-control" value={newLabel}/>
        </div>
        <div className="form-group">
          <label htmlFor="parent-input">Parent</label>
          <input id="parent-input" onChange={changeParent} type="text" className="form-control" value={newParent}/>
        </div>
        <div className="form-group">
          <label htmlFor="user-alias">Personal Alias</label>
          <input id="user-alias" onChange={changeAlias} type="text" className="form-control" value={newAlias}/>
          <p>This alias is used for faster tagging.  It is visible to you.</p>
        </div>
        <button type="submit" className="btn btn-primary">
          <i className="fa fa-save"/>
        </button>
        {
          if tag.item_count <= 0
            <div>
              <button className="btn btn-default" onClick={deleteTag.bind(null, tag)} type="button">
                <i className="fa fa-trash"/>
              </button>
            </div>
        }
      </form>
    </Writer>

    <Writer>
      <h3>Change Icon</h3>
      {
        if choices == null
          <i className="fa fa-spinner fa-spin"/>
        else
          <div className="icon-choice-list">
            {
              choices.map (itemId) ->
                url = Store.resizedURL 'square', itemId
                updateIcon = ->
                  tag.icon_id = itemId
                  item = Store.getItem itemId
                  tag.icon_code = item.code
                  Store.updateTag tag

                <button key={itemId} onClick={updateIcon}>
                  <img src={url}/>
                </button>
            }
          </div>
      }
    </Writer>
  </div>
