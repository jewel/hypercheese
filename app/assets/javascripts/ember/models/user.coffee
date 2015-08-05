attr = DS.attr

App.User = DS.Model.extend
  name: attr()
  comments: DS.hasMany('comment')
