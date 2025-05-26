component 'Writer', ({children}) ->
  return null unless Store.canWrite()
  children
