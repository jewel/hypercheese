#= require react
#= require jquery
#= require jquery_ujs
#= require twitter/bootstrap
#= require_tree .

$ ->
  Store.init()
  ReactDOM.render <GalleryApp/>, document.getElementById('content')
