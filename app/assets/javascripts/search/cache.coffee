class App.SearchResultsCache
  constructor: (str) ->
    @search_string = str

    @start = 0
    @data = []
    @finish = 0
    @updating = false

  get: (index) ->
    throw "No such index in cache" unless @contains index
    @data[index - @start]

  contains: (index) ->
    index >= @start && index < @finish

  update: (start, count, hook) ->
    start -= count * 2
    start = 0 if start < 0
    count *= 5
    return if @updating
    @updating = true
    $.ajax
      dataType: 'json'
      type: 'GET'
      data:
        q: @search_string
        limit: count
        offset: start

      url: "/search/results"

      success: (res) =>
        @start = start
        @finish = start + count
        @data = res
        hook()

      complete: =>
        @updating = false
