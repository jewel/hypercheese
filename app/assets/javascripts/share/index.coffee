#= require react
#= require jquery
#= require jquery_ujs
#= require bootstrap-sprockets
#= require_tree .

$ ->
  shareCode = document.getElementById('share-code').getAttribute('data-share-code')

  Store.init(shareCode)
  ReactDOM.render <ShareApp/>, document.getElementById('content')
