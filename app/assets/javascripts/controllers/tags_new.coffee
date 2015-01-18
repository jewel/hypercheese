App.TagsNewController = Ember.ArrayController.extend
  label: null

  sortProperties: ['label']

  actions:
    createTag: ->
      data = @getProperties(
        'label')

      console.log data

      post = @store.createRecord('tag', data)
    
      post.save().then =>
        @setProperties(
          label: null)

