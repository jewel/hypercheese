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
        for item in res.shares
          @state.items[index] = item.id
          item.index = index
          item.tag_ids = []
          @state.itemsById[item.id] = item
          index++

        @needsRedraw()

    @state =
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

