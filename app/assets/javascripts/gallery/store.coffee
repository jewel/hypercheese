class @Store
  @jax: (params) ->
    params.dataType ||= 'json'
    params.error ||= (xhr, status, error) ->
      alert "Problem with server: #{error}"

    $.ajax params

  @init: ->
    @jax
      url: '/tags'
      success: (res) =>
        @state.tagsLoaded = true
        @state.tags = res.tags
        @_updateTagIndexes()
        @needsRedraw()

    if document.documentElement.clientWidth > 960
      defaultZoom = 7
    else
      defaultZoom = 5

    @state =
      tags: []
      tagsLoaded: false
      tagsById: {}
      tagsByLabel: {}
      tagIconChoices: []
      tagIconChoicesId: null
      details: {}
      searchKey: null
      query: ''
      items: {}
      itemsById: {}
      resultCount: null
      selection: {}
      selectMode: false
      selectionCount: 0
      pendingTags: []
      pendingTagString: ""
      lastTags: []
      rangeStart: null
      dragStart: null
      dragEnd: null
      dragLeftStart: false
      dragging: {}
      zoom: defaultZoom
      lastScrollPosition: null
      highlight: null
      recent: null
      hasTouch: false
      showInfo: false

  @_updateTagIndexes: ->
    @state.tagsById = {}
    @state.tagsByLabel = {}
    for tag in @state.tags
      tag.item_count = 0 if tag.item_count == null
      @state.tagsById[tag.id] = tag
      @state.tagsByLabel[tag.label.toLowerCase()] = tag

  @fetchRecent: ->
    return @state.recent if @state.recent
    blank = {activity: [], sources: []}
    return blank if @loading
    @loading = true
    @jax
      url: '/activity'
      success: (res) =>
        @loading = false
        usersById = {}
        if res.users
          for user in res.users
            usersById[user.id] = user

        for activity in res.activity
          c = activity.comment
          if c && c.user_id
            c.user = usersById[c.user_id]
          s = activity.star
          if s && s.user_id
            s.user = usersById[s.user_id]

        @state.recent = res
        @needsRedraw()
    blank

  @fetchItem: (itemId) ->
    item = @getItem itemId
    return item if item
    return null if @loading

    query = new SearchQuery
    query.parse @state.query

    @loading = true
    @jax
      url: '/items/' + itemId
      data:
        query: query.as_json()
      success: (res) =>
        @loading = false
        index = res.meta.index
        item = res.item
        item.index = index
        @state.items[index] = itemId
        @state.itemsById[itemId] = item
        @needsRedraw()
    null

  @getItem: (itemId) ->
    @state.itemsById[itemId]

  @getIndex: (itemId) ->
    item = @getItem itemId
    return null unless item
    item.index

  @getDetails: (itemId, force=false) ->
    return if !itemId

    item = @getItem itemId
    blank = { comments: [], paths: [], ages: {}, stars: [] }
    if !item
      return blank

    details = @state.details[itemId]
    if details? && !force
      return details

    return blank if @loading
    @loading = true

    @jax
      url: "/items/#{itemId}/details"
      data:
        item_id: itemId
      success: (res) =>
        @loading = false
        details = res.item_details

        usersById = {}
        if res.users
          for user in res.users
            usersById[user.id] = user

        if res.starred_by
          for user in res.starred_by
            usersById[user.id] = user

        commentsById = {}
        for comment in res.comments
          comment.user = usersById[comment.user_id]
          commentsById[comment.id] = comment

        details.comments = []

        for comment_id in details.comment_ids
          details.comments.push commentsById[comment_id]

        details.stars = []
        for user_id in details.starred_by_ids
          details.stars.push usersById[user_id]

        @state.details[itemId] = details
        @needsRedraw()

    return blank

  @newComment: (itemId, text) ->
    @jax
      url: '/comments'
      type: 'POST'
      data:
        'comment[item_id]': itemId
        'comment[text]': text
      success: (res) =>
        res.comment.user = res.users[0]
        item = @state.itemsById[itemId]
        if !item
          console.warn "No such item: #{itemId}"
        else
          item.has_comments = true

        @state.details[itemId].comments.push res.comment
        @needsRedraw()

  @selectItem: (id, value=true) ->
    if value
      if !@state.selection[id]
        @state.selection[id] = true
        @state.selectionCount++
    else
      if @state.selection[id]
        delete @state.selection[id]
        @state.selectionCount--

  @toggleSelection: (id) ->
    @selectItem id, !@state.selection[id]
    @needsRedraw()

  @findRange: (startId, endId) ->
    startIndex = @getIndex startId
    endIndex = @getIndex endId
    return [] unless startIndex? && endIndex?
    if startIndex > endIndex
      temp = startIndex
      startIndex = endIndex
      endIndex = temp

    ids = []
    for index in [startIndex..endIndex]
      id = @state.items[index]
      ids.push id if id

    ids

  @dragRange: ->
    @state.dragging = {}
    items = @findRange @state.dragEnd, @state.dragStart
    for id in items
      @state.dragging[id] = true
    @needsRedraw()

  @selectRange: (itemId, value=true) ->
    if !@state.rangeStart?
      @state.rangeStart = itemId
    items = @findRange @state.rangeStart, itemId
    for id in items
      @selectItem id, value
    @needsRedraw()

  @shareSelection: ->
    ids = []
    for id of @state.selection
      ids.push id

    @jax(
      type: "POST"
      url: "/shares"
      data:
        items: ids
    ).then (res) ->
      res.url

  @clearSelection: ->
    @state.selection = {}
    @state.selectionCount = 0
    @needsRedraw()

  @newTag: (label, icon) ->
    @jax
      url: "/tags"
      data:
        tag:
          label: label
          icon_item_id: icon
      type: "POST"
      success: (res) =>
        @state.tags.push res.tag
        @_updateTagIndexes()
        @needsRedraw()

    null

  @updateTag: (tag) ->
    @jax
      url: "/tags/#{tag.id}"
      data:
        tag: tag
      type: "PUT"
      success: (res) =>
        @state.tags = @state.tags.map (t) ->
          if t.id == tag.id
            res.tag
          else
            t
        @_updateTagIndexes()

        @needsRedraw()

    null

  @deleteTag: (id) ->
    @jax
      url: "/tags/#{id}"
      type: "DELETE"
      success: (res) =>
        @state.tags = @state.tags.filter (tag) -> tag.id != id
        @_updateTagIndexes()
        @needsRedraw()

    null

  @getPendingMatches: ->
    matches = []
    for part in @state.pendingTags
      matches.push part.match if part.match?
    matches

  @addPendingToSelection: ->
    matches = @getPendingMatches()

    if matches.length > 0
      @addTagsToSelection matches

    @state.pendingTags = []
    @state.pendingTagString = ""
    @clearSelection()

  @addTagsToSelection: (tags) ->
    return if tags.length == 0
    @state.lastTags = tags

    tagIds = []
    for tag in tags
      tagIds.push tag.id
      unless tag.icon
        for id of @state.selection
          tag.icon = id
        @updateTag tag

    itemIds = []
    for id of @state.selection
      itemIds.push id

    return if itemIds.length == 0

    @jax
      url: "/items/add_tags"
      data:
        items: itemIds
        tags: tagIds
      type: "POST"
      success: (res) =>
        @_ingestItemUpdates res.items
        @needsRedraw()

    null

  @_ingestItemUpdates: (items) ->
    for item in items
      oldItem = @getItem item.id
      if oldItem
        item.index = oldItem.index
      @state.itemsById[item.id] = item

  @removeTagFromSelection: (tagId) ->
    itemIds = []
    for id of @state.selection
      itemIds.push id

    @jax
      url: "/items/remove_tag"
      data:
        items: itemIds
        tag: tagId
      type: "POST"
      success: (res) =>
        @_ingestItemUpdates res.items
        @needsRedraw()

  @toggleItemStar: (itemId) ->
    @jax
      url: "/items/#{itemId}/toggle_star"
      type: "POST"
      success: (res) =>
        @_ingestItemUpdates [res.item]
        if @state.details[itemId]
          @getDetails itemId, true
        @needsRedraw()

  @setZoom: (level) ->
    @state.zoom = level
    @needsRedraw()

  @search: (q, force=false) ->
    unless force
      return if q == @state.query
    @state.searchKey = null
    @state.query = q
    @state.items = {}
    @state.itemsById = {}
    @state.resultCount = null
    @state.selection = {}
    @state.selectionCount = 0
    @executeSearch 0, 0

  @executeSearch: (start, end) ->
    return unless @state.tagsLoaded
    batchSize = 100

    if @searching
      return

    if @state.resultCount == 0
      return

    # Ask for the data segmented in batches.  Fetch multiple batches at once if
    # needed to account for all data.

    batchStart = start - start % batchSize
    batchEnd = end - end % batchSize + batchSize - 1

    if @state.resultCount != null && batchStart >= @state.resultCount
      batchStart = @state.resultCount - 1

    if @state.resultCount != null && batchEnd >= @state.resultCount
      batchEnd = @state.resultCount - 1

    missing = false
    for i in [batchStart..batchEnd]
      if !@state.items[i]
        missing = true
        break

    return unless missing

    # Trim pieces we already have
    while @state.items[batchStart]
      batchStart++

    while @state.items[batchEnd]
      batchEnd--

    @searching = true

    query = new SearchQuery
    query.parse @state.query

    @searchRequest = @jax
      url: "/items"
      data:
        limit: batchEnd - batchStart + 1
        offset: batchStart
        query: query.as_json()
        search_key: @state.searchKey
      success: (res) =>
        @searching = false

        @state.resultCount = res.meta.total
        for item, i in res.items
          item.index = batchStart + i
          @state.items[item.index] = item.id
          @state.itemsById[item.id] = item

        @state.searchKey = res.meta.search_key

        @needsRedraw()

  @loadIconChoices: (tag) ->
    if tag.id == @state.tagIconChoicesId
      return @state.tagIconChoices

    query = new SearchQuery
    query.options.only = true
    query.options.type = 'photo'
    query.tags = [tag]

    @searching = true
    @jax
      url: "/items"
      data:
        limit: 1000
        offset: 0
        query: query.as_json()
        search_key: null
      success: (res) =>
        @searching = false
        @state.tagIconChoices = []
        for item in res.items
          @state.tagIconChoices.push item.id
        @state.tagIconChoicesId = tag.id

        @needsRedraw()
    return []

  @needsRedraw: ->
    @callback() if @callback

  @navigate: (url) ->
    history.pushState {}, '', '#' + url
    @navigateCallback() if @navigateCallback

  @navigateWithoutHistory: (url) ->
    history.replaceState {}, '', '#' + url
    @navigateCallback() if @navigateCallback

  @onChange: (callback) ->
    @callback = callback

  @onNavigate: (callback) ->
    @navigateCallback = callback
