App.SearchAdapter = App.ApplicationAdapter.extend
  find: (store, type, query) ->
    new Ember.RSVP.Promise (resolve, reject) ->
      $.ajax(
        cache: false
        url: '/search'
        data:
          q: query
        type: 'GET'
        dataType: 'json'
      ).then(
        (data) ->
          data.search.id = query
          unless query
            data.search.id = 'empty-search'
          Ember.run null, resolve, data
        (jqXHR) ->
          jqXHR.then = null
          Ember.run null, reject, jqXHR
      )

App.Search = DS.Model.extend
  adapter: App.SearchAdapter

  items: DS.hasMany('item')
  count: DS.attr('number')
