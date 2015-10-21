#= require react
#= require ../ember
#= require jquery
#= require jquery_ujs
#= require twitter/bootstrap
#= require_tree .

$ ->
  Bridge.init()
  React.render <GalleryApp/>, document.getElementById('content')
