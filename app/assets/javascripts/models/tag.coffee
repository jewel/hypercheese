attr = DS.attr

App.Tag = DS.Model.extend
  label: attr()
  items: DS.hasMany('item')
