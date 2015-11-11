#= require react
#= require jquery
#= require jquery_ujs
#= require bootstrap-sprockets
#= require_tree .

$ ->
  Store.init()
  ReactDOM.render <GalleryApp/>, document.getElementById('content')
