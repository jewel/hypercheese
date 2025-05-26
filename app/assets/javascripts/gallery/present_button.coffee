component 'PresentButton', ({url, streamUrl, video}) ->
  [state, setState] = React.useState
    request: null
    connection: null
    clientId: Date.now().toString()
    connectionStatus: null
    sessionId: null

  currentUrl = React.useRef null

  onMessage = (msg) ->
    data = JSON.parse msg.data
    console.log data
    if data.type == "update_session" || data.type == "new_session"
      console.log data.message.sessionId
      setState (prev) -> {...prev, sessionId: data.message.sessionId}

  onStart = (e) ->
    # Connect to chromecast default receiver.  chrome on desktop supports URLs
    # directly, but on Android it only supports connecting to chromecast apps.
    req = new PresentationRequest "cast:CC1AD845?clientId=#{state.clientId}"
    req.start().then (connection) ->
      setState (prev) -> {...prev, request: req, connection: connection}
      connection.onmessage = onMessage

  connected = ->
    state.connection?.state == 'connected'

  sendMessage = (payload) ->
    return unless connected()

    msg =
      type: "v2_message"
      timeoutMillis: 0
      sequenceNumber: 0
      clientId: state.clientId
      message: payload

    console.log "Sending", msg
    state.connection.send JSON.stringify msg

  seekTo = (time) ->
    sendMessage
      type: "SEEK"
      currentTime: time
      sessionId: state.sessionId
      requestId: 0

  loadIfChanged = ->
    return unless url
    return unless connected()

    url = location.origin + url

    if streamUrl
      url = location.origin + streamUrl

    return if currentUrl.current == url

    if streamUrl
      mimeType = "video/mp4"
    else
      mimeType = "image/jpeg"

    sendMessage
      type: "LOAD"
      media:
        contentId: url
        streamType: "BUFFERED"
        contentType: mimeType
        metadata:
          metadataType: 0
          title: "Hypercheese"
          subtitle: ""
      autoplay: true
      sessionId: state.sessionId
      requestId: 0

    currentUrl.current = url

  useEffect ->
    loadIfChanged()
    ->
  , [url, streamUrl, state.connection, state.sessionId]

  useEffect ->
    return unless video

    onSeeked = ->
      console.log video.currentTime
      seekTo video.currentTime

    video.onseeked = onSeeked

    -> video.onseeked = null
  , [video]

  return null unless PresentationRequest?
  return null unless url

  <ControlIcon
    className={"presentation"}
    active={connected()}
    title="Present"
    onClick={onStart}
    icon="fa-tv"
  />
