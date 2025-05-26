component 'RateButton', ({itemId, icon, rating, type, onNext}) ->
  onRate = (rating) ->
    Store.rate itemId, rating
    onNext()

  classes = ["fa", "fa-fw", icon]
  item = Store.getItem itemId
  return null unless item?
  classes.push "active" if item.rating == type
  <button className="control rate" onClick={-> onRate type }>
    <i className={ classes.join ' ' }/>
  </button>
