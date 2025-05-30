#= require application
#= require ./component
#= require_tree .

$ ->
  shareCode = document.getElementById('share-code').getAttribute('data-share-code')

  Store.init(shareCode)
  root = createRoot document.getElementById('content')
  root.render <ShareApp/>
