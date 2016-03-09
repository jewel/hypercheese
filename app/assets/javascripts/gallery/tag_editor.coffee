@TagEditor = React.createClass
  getInitialState: ->
    newLabel: @props.tag.label

  changeLabel: (e) ->
    @setState
      newLabel: e.target.value

  saveNewLabel: (e) ->
    e.preventDefault()
    @props.tag.label = @state.newLabel
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
        <h2>&ldquo;{tag.label}&rdquo;</h2>
      </div>
      <ul>
        <li>used {tag.item_count.toLocaleString()} times</li>
        <li>search for <a href={"#/search/#{encodeURI(tag.label)}"}>{tag.label}</a></li>
        <li>search for <a href={"#/search/#{encodeURI("only #{tag.label}")}"}>{"only #{tag.label}"}</a></li>
        <li>search for <a href={"#/search/#{encodeURI("video #{tag.label}")}"}>{"video of #{tag.label}"}</a></li>
      </ul>
      <form className="form-inline" onSubmit={@saveNewLabel}>
        {
          if tag.item_count <= 0
            <div>
              <button className="btn btn-default" href="javascript:void(0)" onClick={@deleteTag.bind(@, tag)} type="button">
                <i className="fa fa-trash"/>
              </button>
            </div>
        }
        <input onChange={@changeLabel} type="text" className="form-control" value={@state.newLabel}/>
        <button type="submit" className="btn btn-primary">
          <i className="fa fa-save"/>
        </button>
      </form>

      <h3>Change Icon</h3>
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
    </div>
