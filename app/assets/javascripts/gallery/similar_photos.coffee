component 'SimilarPhotos', ({itemId}) ->
  [state, setState] = useState
    loading: true
    items: []

  navigate = useNavigate()

  useEffect ->
    Store.jax
      url: "/items/#{itemId}/similar"
      success: (res) ->
        setState
          items: res.items
          loading: false
    ->
  , [itemId]

  navigateTo = (item) ->
    (e) ->
      e.preventDefault()
      navigate("/items/#{item.id}", { state: { search: Store.state.query } })

  if state.loading
    return <i className="fa fa-spinner fa-spin" style={fontSize: 48}/>

  if !state.items?
    return <div>Similar items not available</div>

  <div>
    <h3>Similar Items:</h3>
    {
      state.items.map (item) ->
        <Link key={item.id} href={"/items/#{item.id}"} onClick={navigateTo(item)}>
          <img
            key={item.id}
            className="thumb"
            src={Store.resizedURL "square", item}
          />
        </Link>
    }
  </div>
