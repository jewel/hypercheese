App.ItemSquareDisplayComponent = Ember.Component.extend
  classNames: ['item']
  attributeBindings: ['bgStyle:style']

  squareImage: Ember.computed 'item.id', 'zoomed', 'item.variety', ->
    unless @get('item.id')
      return "/images/loading.png"

    size = if @get('zoomed')
      if @get('item.variety') == 'video'
        'exploded'
      else
        'large'
    else
      'square'
    "/data/resized/#{size}/#{@get('item.id')}.jpg"

  imageClass: Ember.computed 'item.isSelected', ->
    if @get("item.isSelected")
      "thumb is-selected"
    else
      "thumb"

  showVideo: Ember.computed 'item.variety', 'zoomed', ->
    @get('zoomed') && @get('item.variety') == 'video'

  videoStream: Ember.computed 'item.id', ->
    unless @get('item.id')
      return ""

    "/data/resized/stream/#{@get('item.id')}.mp4"

  imageStyle: Ember.computed 'maxImageHeight', 'maxImageWidth', 'zoomed', 'item.width', 'item.height', ->
    if @get('zoomed')
      target_width = @get 'maxImageWidth'
      target_height = @get 'maxImageHeight'
      width = @get 'item.width'
      height = @get 'item.height'

      if width > target_width
        height *= target_width / width
        width *= target_width / width

      if height > target_height
        width *= target_height / height
        height *= target_height / height

      margin = 0
      if target_height > height
        margin = Math.floor( (target_height - height) / 2)
      Ember.String.htmlSafe "width: #{Math.floor(width)}px; height: #{Math.floor(height)}px; margin-top: #{margin}px; margin-bottom: #{margin}px"
    else
      Ember.String.htmlSafe "width: #{@get('maxImageWidth')}px; height: #{@get('maxImageHeight')}px;"

  bgcolor: Ember.computed 'item.position', ->
    largePrime = 1103515245
    rand = (@get('item.position') * largePrime + 12345) % 16777216
    '#' + ('000000' + rand.toString(16)).slice(-6)

  bgStyle: Ember.computed 'bgcolor', 'item.isSelected', 'zoomed', ->
    # The background color shines through when an item is selected
    color = if @get('item.isSelected')
      "blue"
    else
      if @get('zoomed')
        "black"
      else
        @get 'bgcolor'
    Ember.String.htmlSafe "background-color: #{color}"

  click: (e) ->
    if e.ctrlKey
      @sendAction @get('toggleSelection'), @get('item')
    else if e.shiftKey
      @sendAction @get('lineSelect'), @get('item')
    else
      @sendAction @get('imageSelect'), @get('item')


  doubleClick: (e) ->
    @sendAction @get('imageZoom'), @get('item')

#  mouseDown: (e) ->
#    if e.which != 1
#      return false
#
#    @wasLongPress = false
#    func = =>
#      @wasLongPress = true
#      @sendAction @imageLongPress, @get('item')
#
#    run = Ember.run.later @, func, 1000
#    @longPress = run
#    true
#
#  mouseUp: (e) ->
#    if e.which != 1
#      return false
#
#    if !@wasLongPress
#      Ember.run.cancel @longPress
#      @sendAction @imageClick, @get('item')
#      true
#    else
#      false
