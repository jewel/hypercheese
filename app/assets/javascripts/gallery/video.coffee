component 'Video', ({itemId, itemCode, poster, setPlaying, toggleControls, showControls, videoRef}) ->
  [showVideoControls, setShowVideoControls] = React.useState false

  pause = ->
    videoRef.current?.pause()
    setShowVideoControls false

  play = ->
    videoRef.current?.play()
    setShowVideoControls true

  currentTime = ->
    videoRef.current?.currentTime

  onVideoPlaying = (e) ->
    setPlaying true

  onVideoPause = (e) ->
    setPlaying false

  onVideoEnded = (e) ->
    setShowVideoControls false
    showControls()

  console.log "video: #{itemId} #{itemCode}"

  <video
    src={Store.resizedURL 'stream', itemId, itemCode}
    ref={videoRef}
    onClick={toggleControls}
    controls={showVideoControls}
    preload="none"
    poster={poster}
    onPause={onVideoPause}
    onPlaying={onVideoPlaying}
    onEnded={onVideoEnded}
    playsInline
  />

