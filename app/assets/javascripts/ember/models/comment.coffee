attr = DS.attr

App.Comment = DS.Model.extend
  text: attr()
  user: DS.belongsTo('user', {async: false})
  item: DS.belongsTo('item', {async: false})
  created_at: attr()
