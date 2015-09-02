attr = DS.attr

App.Tag = DS.Model.extend
  label: attr()
  items: DS.hasMany('item')
  icon: attr('number')
  iconUrl: Ember.computed 'icon', ->
    "/data/resized/square/#{@get('icon')}.jpg"
