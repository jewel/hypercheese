class @TagMatch
  @matchOne: (str) ->
    clean = (str) ->
      str.replace( ' ', '' ).toLowerCase()

    return null if str == ''

    for tag in Store.state.tags
      continue unless clean(tag.label).indexOf( clean(str) ) == 0
      return tag

    return null

  @matchMany: (str, caretPosition) ->
    if !str? || str == ''
      return []

    # check for exact match
    tags = Store.state.tags

    for tag in tags
      continue unless tag.label.toLowerCase() == str.toLowerCase()
      return [ {match: tag, current: true} ]

    results = []
    used = {}

    parts = str.split( /\ +/ )

    pos = 0
    for part in parts
      pos += part.length + 1
      part = part.trim()
      continue if part == ""

      tag = @matchOne part
      if tag
        unless used[tag.id]
          results.push
            match: tag
          used[tag.id] = true
      else
        results.push
          miss: part

      if caretPosition? && pos >= caretPosition
        results[results.length-1].current = true
        caretPosition = null

    results
