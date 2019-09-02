@Results = createReactClass
  render: ->
    <div className="share-results">
      {
        Store.state.items.map (itemId) =>
          item = Store.getItem itemId
          <Item key={item.index} item={item}/>
      }
    </div>
