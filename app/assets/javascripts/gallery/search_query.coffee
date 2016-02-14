class @SearchQuery
  @optionList: 'any only reverse untagged comments orientation type year month source'.split ' '
  @keywords:
    any: true
    only: true
    reverse: true
    untagged: true
    comments: true

  @options:
    orientation: true
    type: true

  @multiple:
    year: true
    month: true
    source: true

  parse: (str) ->
    @options = {}
    @tags = []
    @unknown = []

    # pull out options with values
    str = str.replace /\b(\w+):([-\w,]*)\b/g, (match, key, val) =>
      lkey = key.toLowerCase()
      lval = val.toLowerCase()
      if @constructor.options[lkey]
        @options[lkey] = lval
      else if @constructor.multiple[lkey]
        @options[lkey] = lval.split /,/
      else
        @unknown.push "#{key}:#{val}"
      ""

    # pull out boolean options
    str = str.replace /\b(\w+)\b/g, (match, key) =>
      key = key.toLowerCase()
      if @constructor.keywords[key]
        @options[key] = true
        ""
      else
        match

    # remove commas and extra whitespace
    str = str.replace /,/g, ' '
    str = str.replace /\s+/g, ' '
    str = str.trim()

    # tags can have spaces in their name, so some tag names are ambiguous.
    # Consider the case of tags named "tree", "squirrel", "tree squirrel",
    # For a search of "squirrel tree" we would find ["tree", "squirrel"]
    # for "tree squirrel" we would find ["tree", "tree squirrel"]
    #
    # FIXME have the tag editor show when a tag is going to be masked or is
    # going to mask another tag
    words = str.split " "

    usedTags = {}
    for i in [0...(words.length)]
      if words[i] == null
        continue

      parts = []
      for j in [i...(words.length)]
        word = words[j]
        parts.push word
        name = parts.join(' ').toLowerCase()
        if tag = Store.state.tagsByLabel[name]
          if !usedTags[tag.id]
            @tags.push tag
            usedTags[tag.id] = true
          for k in [i..j]
            words[k] = null
          break

    for word in words
      continue unless word
      if word.match( /^\d{4}$/ )
        @options.year ?= []
        @options.year.push parseInt(word, 10)
        continue
      @unknown.push word

    null

  stringify: ->
    parts = @tags.map (tag) -> tag.label
    for k,v of @options
      if @constructor.keywords[k]
        parts.push k if v == "true" || v == true
      else if @constructor.multiple[k]
        parts.push "#{k}:#{v.join(',')}" if v.length > 0
      else
        parts.push "#{k}:#{v}" if v != ""
    parts = parts.concat @unknown
    parts.join ' '

  as_json: ->
    json = $.extend {}, @options
    json.tags = []
    for tag in @tags
      json.tags.push tag.id
    json
