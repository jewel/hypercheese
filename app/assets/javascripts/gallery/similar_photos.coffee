@SimilarPhotos = createReactClass
  getInitialState: ->
    loading: true
    items: []

  componentDidMount: ->
    Store.jax
      url: "/items/#{@props.itemId}/similar"
      success: (res) =>
        @setState
          items: res.items
          loading: false

  render: ->
    if @state.loading
      return <i className="fa fa-spinner fa-spin" style={fontSize: 48}/>

    if !@state.items?
      return <div>Similar items not available</div>

    <div>
      <h3>Similar Items:</h3>
      {
        @state.items.map (item) ->
          <a href={"/items/#{item.id}"}>
            <img
              key={item.id}
              className="thumb"
              src={Store.resizedURL "square", item}
            />
          </a>
      }
    </div>
