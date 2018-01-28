class @TagMatch
  @matchPrefix: (str) ->
    lower = (str) ->
      str.toLowerCase()
    clean = (str) ->
      lower(str.replace( ' ', '' ))

    str = lower(str).trim()
    tags = []
    # Check for exact match
    for tag in Store.state.tags
      continue unless clean(tag.alias || tag.label) == str || lower(tag.alias || tag.label) == str
      tags.push tag

    # Check for prefix match
    for tag in Store.state.tags
      continue unless clean(tag.alias || tag.label).indexOf( str ) == 0 || lower(tag.alias || tag.label).indexOf( str ) == 0
      tags.push tag

    return tags


  @matchMany: (str, caretPosition) ->
    if !str? || str == ''
      return []

    tags = Store.state.tags

    results = []
    used = {}

    parts = str.split( /\ / )

    # split adds extra ""s when theres a trailing space
    # FIXME Causes parts to be wrong if there is a double space between 2 search terms
    parts = parts.filter (p) ->
      p != ""

    pos = 0
    posOfParts = []

    for part in parts
      # pos to the end of the part
      pos += part.length
      posOfParts.push pos
      pos += 1 # space char

    foundCurrent = false

    for part, index in parts
      matchedPrefixes = []
      continue if part == ""
      pos = posOfParts[index]

      # try to match a pair of words to a tag first
      if index < parts.length - 1
        matchedPrefixes = @matchPrefix part + ' ' + parts[index + 1]
        if matchedPrefixes.length > 0
          parts[index + 1] = ""
          pos = posOfParts[index + 1]

      # otherwise just match one word
      if matchedPrefixes.length == 0
        matchedPrefixes = @matchPrefix part

      if matchedPrefixes.length > 0
        tag = matchedPrefixes.shift()
        unless used[tag.id]
          if !foundCurrent && caretPosition? && pos >= caretPosition
            current = true
            caretPosition = null
            foundCurrent = true
          else
            current = false

          results.push
            match: tag
            current: current
            otherTags: matchedPrefixes
          used[tag.id] = true
      else
        results.push
          miss: part

    results
