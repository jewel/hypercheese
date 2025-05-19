# This behaves the same way as the gallery module's Store, but it only has a
# fraction of the functionality.  Only the features used by the Details widget
# are needed.

class @Store
  @jax: (params) ->
    params.dataType ||= 'json'
    params.error ||= (xhr, status, error) ->
      alert "Problem with server: #{error}"

    $.ajax params

  @init: (shareCode) ->
    @jax
      url: "/shares/#{shareCode}/items"
      success: (res) =>
        @state.items = []
        index = 0
        for item in res.items
          @state.items[index] = item.id
          item.index = index
          item.tag_ids = []
          @state.itemsById[item.id] = item
          index++

        @state.loading = false

        @needsRedraw()

    @state =
      loading: true
      items: []
      itemsById: {}
      showItem: null
      shareCode: shareCode

  @fetchItem: (itemId) ->
    @getItem itemId

  @getItem: (itemId) ->
    @state.itemsById[itemId]

  @getIndex: (itemId) ->
    index = 0
    for id in @state.items
      return index if id == itemId
      index++
    return null

  @executeSearch: ->
    null

  @resizedURL: (size, id, code) ->
    if id?.code
      item = id
    else
      item =
        id: id
        code: code

    ext = "jpg"
    ext = "mp4" if size == 'stream'

    if item.id == null
      return "/images/unknown-icon.png"

    if item.code
      filename = "#{item.id}-#{item.code}"
    else
      # rely on server-side redirect
      filename = "#{item.id}"
    "/data/resized/#{size}/#{filename}.#{ext}"

  @needsRedraw: ->
    @callback() if @callback

  @navigate: (url) ->
    # Save off scroll position in old state
    history.replaceState {scrollPos: window.scrollY}, '', window.location
    history.pushState {}, '', url
    @navigateCallback() if @navigateCallback

  @navigateWithoutHistory: (url) ->
    history.replaceState {}, '', url
    @navigateCallback() if @navigateCallback

  @navigateBack: ->
    history.back()

  @onChange: (callback) ->
    @callback = callback

  @onNavigate: (callback) ->
    @navigateCallback = callback

