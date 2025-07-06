#= require application
#= require rails-ujs
#= require ./component
#= require ./error_boundary
#= require_tree .

$ ->
  # Check if we're in share mode
  shareCodeElement = document.getElementById('share-code')
  shareModeElement = document.getElementById('share-mode')
  
  if shareCodeElement && shareModeElement
    shareCode = shareCodeElement.getAttribute('data-share-code')
    Store.initShare(shareCode)
  else
    Store.init()
  
  root = createRoot document.getElementById('content')
  root.render <GalleryApp/>
