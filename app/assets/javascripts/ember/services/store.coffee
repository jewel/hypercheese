# http://emberjs.com/guides/models/pushing-records-into-the-store/
#App.ApplicationSerializer = DS.ActiveModelSerializer.extend()
#App.ServicesStore = DS.Store.extend()

# Override the default adapter with the `DS.ActiveModelAdapter` which
# is built to work nicely with the ActiveModel::Serializers gem.

Ember.View.reopen({
  didInsertElement: ->
    @_super()
    Ember.run.scheduleOnce "afterRender", @, @afterRenderEvent
    return

  afterRenderEvent: ->
})
