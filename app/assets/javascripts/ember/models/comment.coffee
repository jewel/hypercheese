attr = DS.attr

App.Comment = DS.Model.extend
  text: attr()
  user: DS.belongsTo('user')
  item: DS.belongsTo('item')
  createdAt: attr()
