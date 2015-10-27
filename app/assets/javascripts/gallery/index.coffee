#= require react
#= require jquery
#= require jquery_ujs
#= require twitter/bootstrap
#= require_tree .

$ ->
  Store.init()
  React.render <GalleryApp/>, document.getElementById('content')
