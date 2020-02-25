@Video = createReactClass
  getInitialState: ->
    showVideoControls: false

  pause: ->
    @refs.video.pause()
    @setState
      showVideoControls: false

  play: ->
    @refs.video.play()
    @setState
      showVideoControls: true

  onVideoPlaying: (e) ->
    @props.setPlaying true

  onVideoPause: (e) ->
    @props.setPlaying false

  onVideoEnded: (e) ->
    @setState
      showVideoControls: false
    @props.showControls()

  render: ->
    <video
      src={Store.resizedURL 'stream', @props.itemId, @props.itemCode}
      ref="video"
      onClick={@props.toggleControls}
      controls={@state.showVideoControls}
      preload="none"
      poster={@props.poster}
      onPause={@onVideoPause}
      onPlaying={@onVideoPlaying}
      onEnded={@onVideoEnded}
      playsInline=true
    />

