@RateButton = React.createClass
  onRate: (rating) ->
    Store.rate @props.itemId, rating

  render: ->
    classes = ["fa", "fa-fw", @props.icon]
    item = Store.getItem @props.itemId
    return null unless item?
    classes.push "active" if item.rating == @props.type
    <a className="control rate" href="javascript:void(0)" onClick={=> @onRate @props.type }>
      <i className={ classes.join ' ' }/>
    </a>


