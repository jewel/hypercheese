@PresentButton = createReactClass
  getInitialState: ->
    request: null
    connection: null
    clientId: Date.now().toString()
    connectionStatus: null

  onMessage: (msg) ->
    data = JSON.parse msg.data
    console.log data
    if data.type == "update_session" || data.type == "new_session"
      console.log data.message.sessionId
      @setState
        sessionId: data.message.sessionId

  onStart: (e) ->
    # Connect to chromecast default receiver.  chrome on desktop supports URLs
    # directly, but on Android it only supports connecting to chromecast apps.
    req = new PresentationRequest("cast:CC1AD845?clientId=#{@state.clientId}")
    req.start().then (connection) =>
      @setState
        request: req
        connection: connection
      connection.onmessage = @onMessage

  loadIfChanged: ->
    return unless @props.url
    return unless @connected()

    url = location.origin + @props.url

    if @props.streamUrl
      url = location.origin + @props.streamUrl

    return if @currentUrl == url

    if @props.streamUrl
      mimeType = "video/mp4"
    else
      mimeType = "image/jpeg"

    @sendMessage
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
      sessionId: @state.sessionId
      requestId: 0

    @currentUrl = url

  connected: ->
    @state.connection?.state == 'connected'

  sendMessage: (payload) ->
    return unless @connected()

    msg =
      type: "v2_message"
      timeoutMillis: 0
      sequenceNumber: 0
      clientId: @state.clientId
      message: payload

    console.log "Sending", msg
    @state.connection.send JSON.stringify msg

  seekTo: (time) ->
    @sendMessage
      type: "SEEK"
      currentTime: time
      sessionId: @state.sessionId
      requestId: 0

  subscribeSeeks: ->
    console.log @props.video
    return unless @props.video

    @props.video.onseeked = =>
      console.log @props.video.currentTime
      @seekTo @props.video.currentTime


  render: ->
    return null unless PresentationRequest?
    return null unless @props.url

    @loadIfChanged()
    @subscribeSeeks()

    <ControlIcon
      className={"presentation"}
      active={@connected()}
      title="Present"
      onClick={@onStart}
      icon="fa-tv"
    />
