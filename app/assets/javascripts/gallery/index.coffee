#= require application
#= require rails-ujs
#= require ./component
#= require ./error_boundary
#= require_tree .

$ ->
  Store.init()
  root = createRoot document.getElementById('content')
  root.render <GalleryAppRoot/>
