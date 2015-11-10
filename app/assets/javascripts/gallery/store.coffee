class @Store
  @jax: (params) ->
    params.dataType ||= 'json'
    params.error ||= (xhr, status, error) ->
      alert "Problem with server: #{status}"

    $.ajax params

  @init: ->
    @jax
      url: '/tags'
      success: (res) =>
        @state.tags = res.tags
        @state.tagsById = []
        for tag in res.tags
          @state.tagsById[tag.id] = tag
        @forceUpdate()

    @state =
      tags: []
      tagsById: {}
      details: {}
      searchKey: null
      query: ''
      items: {}
      itemsById: {}
      resultCount: null
      selection: {}
      selectionCount: 0
      rangeStart: null
      dragStart: null
      dragEnd: null
      dragLeftStart: false
      dragging: {}
      zoom: 5
      selecting: false
      lastScrollPosition: null
      highlight: null
      recent: null

  @fetchRecent: ->
    return @state.recent if @state.recent
    blank = {activity: []}
    return blank if @loading
    @loading = true
    @jax
      url: '/activity'
      success: (res) =>
        @loading = false
        @state.recent = res
        @forceUpdate()
    blank

  @fetchItem: (itemId) ->
    item = @getItem itemId
    return item if item
    return null if @loading
    @loading = true
    @jax
      url: '/items/' + itemId
      data:
        query: @state.query
      success: (res) =>
        @loading = false
        index = res.meta.index
        item = res.item
        item.index = index
        @state.items[index] = itemId
        @state.itemsById[itemId] = item
        @forceUpdate()
    null

  @getItem: (itemId) ->
    @state.itemsById[itemId]

  @getIndex: (itemId) ->
    item = @getItem itemId
    return null unless item
    item.index

  @getDetails: (itemId) ->
    return if !itemId

    item = @getItem itemId
    blank = { comments: [], paths: [], ages: {} }
    if !item
      return blank

    details = @state.details[itemId]
    if details?
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

        commentsById = {}
        for comment in res.comments
          comment.user = usersById[comment.user_id]
          commentsById[comment.id] = comment

        details.comments = []

        for comment_id in details.comment_ids
          details.comments.push commentsById[comment_id]

        @state.details[itemId] = details
        @forceUpdate()

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
        @forceUpdate()

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
    @forceUpdate()

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
    @forceUpdate()

  @selectRange: (itemId, value=true) ->
    if !@state.rangeStart?
      @state.rangeStart = itemId
    items = @findRange @state.rangeStart, itemId
    for id in items
      @selectItem id, value
    @forceUpdate()

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
    @state.selecting = false
    @state.selection = {}
    @state.selectionCount = 0
    @forceUpdate()

  @addTagsToSelection: (tags) ->
    tagIds = []
    for tag in tags
      tagIds.push tag.id

    itemIds = []
    for id of @state.selection
      itemIds.push id

    @jax
      url: "/items/add_tags"
      data:
        items: itemIds
        tags: tagIds
      type: "POST"
      success: (res) =>
        @_ingestItemUpdates res.items
        @forceUpdate()

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
        @forceUpdate()

  @setZoom: (level) ->
    @state.zoom = level
    @forceUpdate()

  @search: (q) ->
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

    @searchRequest = @jax
      url: "/items"
      data:
        limit: batchEnd - batchStart + 1
        offset: batchStart
        query: @state.query
        search_key: @state.searchKey
      success: (res) =>
        @searching = false

        @state.resultCount = res.meta.total
        for item, i in res.items
          item.index = batchStart + i
          @state.items[item.index] = item.id
          @state.itemsById[item.id] = item

        @state.searchKey = res.meta.search_key

        @forceUpdate()

  @forceUpdate: ->
    @callback() if @callback

  @onChange: (callback) ->
    @callback = callback
