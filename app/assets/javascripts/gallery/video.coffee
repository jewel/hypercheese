component 'Video', ({itemId, itemCode, poster, setPlaying, toggleControls, showControls, videoRef, speedSegments}) ->
  [showVideoControls, setShowVideoControls] = React.useState false
  [currentSegment, setCurrentSegment] = React.useState null

  # Initialize speed segments from props or fetch from server
  segments = React.useMemo ->
    if speedSegments && speedSegments.length > 0
      speedSegments
    else
      []
  , [speedSegments]

  # Find the appropriate speed segment for current time
  findSegmentForTime = React.useCallback (currentTime) ->
    if segments.length > 0
      segment = segments.find (seg) ->
        currentTime >= seg.start_time && currentTime < seg.end_time
      segment || segments[segments.length - 1]  # Use last segment if past end
    else
      null
  , [segments]

  # Handle time updates to adjust playback speed
  onTimeUpdate = React.useCallback (e) ->
    return unless videoRef.current && segments.length > 0
    
    currentTime = videoRef.current.currentTime
    targetSegment = findSegmentForTime(currentTime)
    
    if targetSegment && (!currentSegment || currentSegment.playback_rate != targetSegment.playback_rate)
      videoRef.current.playbackRate = targetSegment.playback_rate
      setCurrentSegment(targetSegment)
  , [videoRef, segments, currentSegment, findSegmentForTime]

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

  onLoadedMetadata = (e) ->
    # Initialize playback rate for first segment if available
    if segments.length > 0
      firstSegment = segments[0]
      if videoRef.current && firstSegment
        videoRef.current.playbackRate = firstSegment.playback_rate
        setCurrentSegment(firstSegment)

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
    onTimeUpdate={onTimeUpdate}
    onLoadedMetadata={onLoadedMetadata}
    playsInline
  />

