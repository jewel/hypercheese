#= require application
#= require bootstrap-sprockets
#= require ./component
#= require ./error_boundary
#= require_tree .

$ ->
  Store.init()
  root = createRoot document.getElementById('content')
  root.render <GalleryApp/>
