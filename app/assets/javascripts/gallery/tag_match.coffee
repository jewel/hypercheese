class @TagMatch
  @matchOne: (str) ->
    return null if str == ''

    for tag in Store.state.tags
      continue unless tag.label.toLowerCase().indexOf( str.toLowerCase() ) == 0
      return tag

    return null

  @matchMany: (str) ->
    if !str? || str == ''
      return []

    # check for exact match
    tags = Store.state.tags

    for tag in tags
      continue unless tag.label.toLowerCase() == str.toLowerCase()
      return [tag]

    # attempt to split by comma
    matches = []
    for part in str.split( /,\ */ )
      res = @matchOne part
      matches.push res if res

    return matches if matches.length > 0

    # attempt to split by whitespace
    for part in str.split( /\ +/ )
      res = @matchOne part
      matches.push res if res

    return matches if matches.length > 0

    return []
