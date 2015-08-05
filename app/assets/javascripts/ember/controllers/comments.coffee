App.CommentsController = Ember.Controller.extend
  sortProperties: ['createdAt']

  actions:
    comment: ->
      data = @getProperties 'text', 'item'
      comment = @store.createRecord 'comment', data
      comment.save().then =>
        @set('text', '')

