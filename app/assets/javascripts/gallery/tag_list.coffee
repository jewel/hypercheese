@TagList = React.createClass
  getInitialState: ->
    filter: ""

  updateFilter: (e) ->
    @setState
      filter: e.target.value

  filterTest: (tag) ->
    for part in @state.filter.split(/\s+/)
      part = part.toLowerCase()
      return false if tag.label.toLowerCase().indexOf(part) == -1

    true

  newTag: ->
    label = window.prompt("Tag name", "Untitled")
    if label != null
      Store.newTag(label, null)

  render: ->
    tags = Store.state.tags
    <div className="container-fluid tag-list-page">
      <a className="pull-right" href="#/"><i className="fa fa-times"/></a>
      <h1>HyperCheese Tag Editor</h1>
      <div className="col-xs-3 input-group">
        <span className="input-group-addon"><i className="fa fa-search fa-fw"/></span>
        <input type="text" onChange={@updateFilter} className="form-control" placeholder="Filter..." value={@state.filter}/>
      </div>

      <div className="tag-list">
        <div className="new-tag">
          <a href="javascript:void(0)" onClick={@newTag}>
            <i className="fa fa-plus-circle"/>
          </a>
          <br/>
          <em>
            New Tag
          </em>
        </div>
        {
          tags.map (tag) =>
            if @filterTest(tag)
              <div key={tag.id} className="tag">
                <a href={"#/tags/#{tag.id}/#{encodeURI tag.label}"}>
                  <Tag tag=tag />
                </a>
                {" #{tag.label} (#{tag.item_count.toLocaleString()}) "}
              </div>
        }
      </div>
      <p>Total: {tags.length.toLocaleString()}</p>
    </div>
