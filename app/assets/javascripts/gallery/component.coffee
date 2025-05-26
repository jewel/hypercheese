@component = (name, func) ->
  func.displayName = name
  @[name] = func
  null
