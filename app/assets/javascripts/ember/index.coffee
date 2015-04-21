#= require jquery
#= require jquery_ujs
#= require ember.glimmer.template-compiler
#= require ember.glimmer
#= require ember-data
#= require ic-autocomplete
#= require twitter/bootstrap
#= require_self
#= require ./store
#= require_tree ./misc
#= require_tree ./models
#= require_tree ./mixins
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./helpers
#= require_tree ./components
#= require_tree ./templates
#= require_tree ./routes
#= require ./router

# for more details see: http://emberjs.com/guides/application/
window.App = Ember.Application.create()
