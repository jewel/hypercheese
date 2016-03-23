class @TagMatch
  @matchOne: (str) ->
    lower = (str) ->
      str.toLowerCase()
    clean = (str) ->
      lower(str.replace( ' ', '' ))

    str = lower(str).trim()
    # Check for exact match
    for tag in Store.state.tags
      continue unless clean(tag.label) == str || lower(tag.label) == str
      return tag

    # Check for prefix match
    for tag in Store.state.tags
      continue unless clean(tag.label).indexOf( str ) == 0 || lower(tag.label).indexOf( str ) == 0
      return tag

    return null


  @matchMany: (str, caretPosition) ->
    if !str? || str == ''
      return []

    # check for exact match
    tags = Store.state.tags

    results = []
    used = {}

    parts = str.split( /\ / )

    pos = 0
    posOfParts = []

    for part in parts
      # pos to the end of the part
      pos += part.length
      posOfParts.push pos
      pos += 1 # space char

    for part, index in parts
      tag = null
      continue if part == ""
      pos = posOfParts[index]

      # try to match a pair of words to a tag first
      if index < parts.length - 1
        tag = @matchOne part + ' ' + parts[index + 1]
        if tag
          parts[index + 1] = ""
          pos = posOfParts[index + 1]

      # otherwise just match one word
      tag ||= @matchOne part
      if tag
        unless used[tag.id]
          if caretPosition? && pos >= caretPosition
            current = true
            caretPosition = null
          else
            current = false

          results.push
            match: tag
            current: current
          used[tag.id] = true
      else
        results.push
          miss: part

    results
