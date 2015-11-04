@ContextMenu = React.createClass
  render: ->
    download_label = if Store.state.selectionCount > 0
      "Download #{Store.state.selectionCount} items"
    else
      "Download from Cheese"
    <menu type="context" id="cheesemenu">
      <menuitem label=download_label onClick={-> alert 'coming soon'}/>
    </menu>
