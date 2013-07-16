class App.Tag extends Spine.Model
  @configure 'Tag', 'label'
  @extend Spine.Model.Ajax

  @findByLabel = (label) =>
    for tag in App.Tag.all()
      return tag if label == tag.label
    null
