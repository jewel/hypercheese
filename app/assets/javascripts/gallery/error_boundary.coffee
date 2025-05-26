@ErrorBoundary = createReactClass
  getInitialState: ->
    hasError: false
    error: null

  componentDidCatch: (error, info) ->
    @setState
      hasError: true
      error: error

  render: ->
    if @state.hasError
      <div className="error-boundary">
        <h2>Something went wrong in this component:</h2>
        <pre>{@state.error?.toString()}</pre>
        <pre>{@state.error?.stack}</pre>
      </div>
    else
      @props.children

@withErrorBoundary = (Component) ->
  (props) ->
    <ErrorBoundary>
      <Component {...props}/>
    </ErrorBoundary>
