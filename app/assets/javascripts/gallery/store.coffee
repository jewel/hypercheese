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

    @search ''

  @toggleSelection: (id) ->
    if @state.selection[id]
      delete @state.selection[id]
      @state.selectionCount--
    else
      @state.selection[id] = true
      @state.selectionCount++
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
      oldItem = @state.itemsById[item.id]
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

  @search: (q) ->
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
      success: (res) =>
        @searching = false

        if @state.resultCount != null && @state.resultCount != res.meta.total
          # invalidate all other results, the number of results has changed
          console.log "Result count has changed, discarding cache"
          @state.items = {}
          @state.itemsById = {}

        @state.resultCount = res.meta.total
        for item, i in res.items
          item.index = batchStart + i
          @state.items[item.index] = item.id
          @state.itemsById[item.id] = item

        @forceUpdate()

  @forceUpdate: ->
    @callback() if @callback

  @onChange: (callback) ->
    @callback = callback
