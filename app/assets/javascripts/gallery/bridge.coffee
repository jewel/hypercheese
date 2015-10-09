class @Bridge
  @init: ->
    @store = App.__container__.lookup('service:store')

    # Initial loads
    @tags = @store.findAll('tag')
    @tags.addObserver( '@each', @update )

  @dump: ->
    state =
      tags: @toNative( @tags.slice() )
    state

  @update: =>
    @callback @dump()

  @toNative: (obj) ->
    # FIXME: This is probably not the most efficient way to do this
    JSON.parse JSON.stringify(obj)

  @onChange: (callback) ->
    @callback = callback

$ ->
  Bridge.onChange (data) ->
    console.log data
  Bridge.init()
