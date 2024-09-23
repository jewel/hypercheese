@PresentButton = createReactClass
  getInitialState: ->
    request: null
    connection: null
    clientId: Date.now().toString()
    connectionStatus: null

  onMessage: (msg) ->
    data = JSON.parse msg.data
    console.log data
    if data.type == "update_session"
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

  send: ->
    return unless @props.url
    return unless @state.connection
    return unless @state.connection.state == 'connected'

    url = location.origin + @props.url

    if @props.streamUrl
      url = location.origin + @props.streamUrl

    return if @currentUrl == url

    if @props.streamUrl
      mimeType = "video/mp4"
    else
      mimeType = "image/jpeg"

    msg =
      type: "v2_message"
      timeoutMillis: 0
      sequenceNumber: 0
      clientId: @state.clientId
      message:
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

    console.log "Sending", msg
    @state.connection.send JSON.stringify msg

    @currentUrl = url

  render: ->
    return null unless PresentationRequest?
    return null unless @props.url

    @send()

    <ControlIcon
      className={"presentation"}
      active={@state.connection?.state == "connected"}
      title="Present"
      onClick={@onStart}
      icon="fa-tv"
    />
