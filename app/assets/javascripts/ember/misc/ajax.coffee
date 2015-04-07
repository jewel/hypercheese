# Wrap the jquery ajax call with an RSVP promise instead of a jquery one
App.Ajax = (opts) ->
  opts.dataType = "json"

  new Ember.RSVP.Promise (resolve, reject) ->
    $.ajax( opts ).then(
      (data) ->
        Ember.run null, resolve, data
      (jqXHR) ->
        jqXHR.then = null
        Ember.run null, reject, jqXHR
    )
