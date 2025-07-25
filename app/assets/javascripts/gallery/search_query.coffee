class @SearchQuery
  @optionList: 'not any only reverse untagged item path comment has_comments orientation type year month day source'.split ' '
  @keywords:
    any: true
    only: true
    reverse: true
    untagged: true
    unjudged: true
    has_comments: true
    starred: true
    faces: true

  @options:
    orientation: true
    type: true
    sort: true
    shared: true
    not: true
    age: true
    path: true
    comment: true
    visibility: true
    threshold: true
    in: true
    near: true
    miles: true
    duration: true

  @multiple:
    year: true
    month: true
    day: true
    source: true
    item: true

  @caseSensitive:
    shared: true

  @months: 'January February March April May June July August September October November December'.split ' '

  constructor: (str = '', caretPosition = 0) ->
    @options = {}
    @tags = []
    @unknown = []
    @useOthers = false
    @others = []

    # Extract quoted strings first and adjust caretPosition
    adjustedCaretPosition = caretPosition
    str = str.replace /"(.*?)"/g, (match, query, offset) =>
      if offset < caretPosition
        # If the quote starts before caret, we need to adjust caretPosition
        if offset + match.length < caretPosition
          # If caret is after the quote, reduce by the length of the quote
          adjustedCaretPosition -= match.length
        else
          # If caret is inside the quote, move it to the start of the quote
          adjustedCaretPosition = offset
      @options.clip = query
      ""

    # Now do tag matching with adjusted caret position
    parts = TagMatch.matchMany(str, adjustedCaretPosition)
    unused = []
    for part in parts
      if part.miss
        unused.push part.miss
      else
        @tags.push part.match
        if part.current
          @useOthers = true
          @others = part.otherTags

    str = unused.join ' '

    # pull out options with values
    str = str.replace /\b(\w+):(.*?)(?: |$)/g, (match, key, val) =>
      lkey = key.toLowerCase()
      if @constructor.caseSensitive[lkey]
        lval = val
      else
        lval = val.toLowerCase()
      if @constructor.options[lkey]
        @options[lkey] = lval
      else if @constructor.multiple[lkey]
        @options[lkey] = lval.split /,/
      else
        @unknown.push "#{key}:#{val}"
      ""

    # parse month strings
    if @options.month
      months = []
      for m in @options.month
        if m.length < 3
          continue
        for month in @constructor.months
          if month.toLowerCase().indexOf(m.toLowerCase()) == 0
            months.push month
      @options.month = months

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

    words = str.split " "

    for word in words
      continue unless word
      word = word.toLowerCase()
      if word.match( /^\d{4}$/ )
        @options.year ?= []
        @options.year.push parseInt(word, 10)
        continue

      if word.match( /^(videos?|movies?)$/ )
        @options.type = 'video'
        continue

      if word.match( /^(photos?|pictures?|pics)$/ )
        @options.type = 'photo'
        continue

      # Look for bare months
      if word.length >= 3
        skip = false
        for month in @constructor.months
          if month.toLowerCase().indexOf(word.toLowerCase()) == 0
            @options.month ?= []
            @options.month.push month
            skip = true
        continue if skip

      # Words that don't otherwise match turn into a CLIP search

      # A word that starts with a plus is forced into CLIP
      if word.startsWith "+"
        word = word.slice(1)

      @options.clip ?= ""
      @options.clip += " #{word}"

    if @options.clip
      @options.clip = @options.clip.trim()

    null

  stringify: ->
    parts = @tags.map (tag) -> tag.alias || tag.label
    for k,v of @options
      if k == "clip"
        if v.includes(" ")
          parts.push "\"#{v}\""
        else if TagMatch.matchPrefix(v).length > 0
          parts.push "+#{v}"
        else
          parts.push v
      else if @constructor.keywords[k]
        parts.push k if v == "true" || v == true
      else if @constructor.multiple[k]
        parts.push "#{k}:#{v.join(',')}" if v.length > 0
      else
        parts.push "#{k}:#{v}" if v != ""
    parts = parts.concat @unknown
    parts.join ' '

  as_json: ->
    json = $.extend {}, @options
    if json.month
      json.month = json.month.map (m) => @constructor.months.indexOf(m) + 1
    json.tags = []
    for tag in @tags
      json.tags.push tag.id
    json
