App.PaginationBaseComponent = Ember.Component.extend
  tagName: 'button'
  classNames: 'btn btn-default'
  attributeBindings: ['disabled']
  enabled: true
  disabled: Ember.computed.not('enabled')
  action: null
  click: -> 
    @sendAction()

