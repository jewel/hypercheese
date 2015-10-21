#= require jquery
#= require jquery_ujs
#= require ember
#= require ./hide-deprecations
#= require ember-data
#= require_self
#= require ./store
#= require_tree ./misc
#= require_tree ./adapters
#= require_tree ./models

# for more details see: http://emberjs.com/guides/application/
window.App = Ember.Application.create
  LOG_TRANSITIONS: true
