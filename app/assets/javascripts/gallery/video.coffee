component 'Video', ({itemId, itemCode, poster, setPlaying, toggleControls, showControls, videoRef}) ->
  [showVideoControls, setShowVideoControls] = React.useState false

  onVideoPlaying = (e) ->
    setPlaying true
    setShowVideoControls true

  onVideoPause = (e) ->
    setPlaying false
    setShowVideoControls false

  onVideoEnded = (e) ->
    setPlaying false
    setShowVideoControls false
    showControls()

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

