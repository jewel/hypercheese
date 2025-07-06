component 'SpeedSegmentEditor', ({itemId, segments, onSegmentsChange}) ->
  [editingSegments, setEditingSegments] = React.useState(segments || [])
  [isExtractingSegments, setIsExtractingSegments] = React.useState(false)
  [message, setMessage] = React.useState('')

  # Update editing segments when props change
  React.useEffect ->
    setEditingSegments(segments || [])
  , [segments]

  # Add a new segment
  addSegment = ->
    lastSegment = editingSegments[editingSegments.length - 1]
    startTime = if lastSegment then lastSegment.end_time else 0
    
    newSegment = {
      id: Date.now(), # Temporary ID for new segments
      start_time: startTime,
      end_time: startTime + 5.0,
      playback_rate: 1.0,
      source_type: 'manual',
      isNew: true
    }
    
    setEditingSegments([...editingSegments, newSegment])

  # Remove a segment
  removeSegment = (index) ->
    newSegments = editingSegments.filter((_, i) -> i != index)
    setEditingSegments(newSegments)

  # Update a segment field
  updateSegment = (index, field, value) ->
    newSegments = [...editingSegments]
    newSegments[index] = { ...newSegments[index], [field]: parseFloat(value) || 0 }
    setEditingSegments(newSegments)

  # Save segments to server
  saveSegments = ->
    # TODO: Implement API calls to save segments
    console.log('Saving segments:', editingSegments)
    onSegmentsChange?(editingSegments)
    setMessage('Segments saved successfully!')
    setTimeout(-> setMessage(''), 3000)

  # Extract segments from video metadata
  extractSegments = ->
    setIsExtractingSegments(true)
    setMessage('Extracting speed segments from video metadata...')
    
    fetch("/items/#{itemId}/video_speed_segments/extract", {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
      }
    })
    .then(response -> response.json())
    .then((data) ->
      if data.segments
        setEditingSegments(data.segments)
        setMessage(data.message || 'Segments extracted successfully!')
        onSegmentsChange?(data.segments)
      else
        setMessage(data.message || 'No segments found')
    )
    .catch((error) ->
      console.error('Error extracting segments:', error)
      setMessage('Error extracting segments: ' + error.message)
    )
    .finally(->
      setIsExtractingSegments(false)
      setTimeout(-> setMessage(''), 5000)
    )

  # Format time for display
  formatTime = (seconds) ->
    minutes = Math.floor(seconds / 60)
    secs = (seconds % 60).toFixed(1)
    "#{minutes}:#{if secs < 10 then '0' else ''}#{secs}"

  <div className="speed-segment-editor">
    <div className="editor-header">
      <h3>Speed Segments</h3>
      <div className="editor-controls">
        <button 
          onClick={extractSegments} 
          disabled={isExtractingSegments}
          className="btn btn-primary"
        >
          {if isExtractingSegments then 'Extracting...' else 'Extract from Metadata'}
        </button>
        <button onClick={addSegment} className="btn btn-secondary">
          Add Segment
        </button>
        <button onClick={saveSegments} className="btn btn-success">
          Save Changes
        </button>
      </div>
    </div>

    {if message
      <div className="alert alert-info">
        {message}
      </div>
    }

    <div className="segments-list">
      {editingSegments.map((segment, index) ->
        <div key={segment.id || index} className="segment-row">
          <div className="segment-field">
            <label>Start Time (s)</label>
            <input 
              type="number" 
              step="0.1"
              value={segment.start_time}
              onChange={(e) -> updateSegment(index, 'start_time', e.target.value)}
            />
            <small>{formatTime(segment.start_time)}</small>
          </div>
          
          <div className="segment-field">
            <label>End Time (s)</label>
            <input 
              type="number" 
              step="0.1"
              value={segment.end_time}
              onChange={(e) -> updateSegment(index, 'end_time', e.target.value)}
            />
            <small>{formatTime(segment.end_time)}</small>
          </div>
          
          <div className="segment-field">
            <label>Playback Rate</label>
            <select 
              value={segment.playback_rate}
              onChange={(e) -> updateSegment(index, 'playback_rate', e.target.value)}
            >
              <option value="0.125">1/8x (Very Slow)</option>
              <option value="0.25">1/4x (Slow)</option>
              <option value="0.5">1/2x (Half Speed)</option>
              <option value="1.0">1x (Normal)</option>
              <option value="1.5">1.5x (Faster)</option>
              <option value="2.0">2x (Double Speed)</option>
            </select>
          </div>
          
          <div className="segment-actions">
            <button 
              onClick={-> removeSegment(index)}
              className="btn btn-danger btn-sm"
              title="Remove Segment"
            >
              <i className="fas fa-trash"></i>
            </button>
          </div>
        </div>
      )}
      
      {if editingSegments.length == 0
        <div className="no-segments">
          <p>No speed segments defined. Click "Extract from Metadata" to try automatic detection, or "Add Segment" to create manually.</p>
        </div>
      }
    </div>

    <div className="editor-info">
      <h4>Tips:</h4>
      <ul>
        <li>Segments should not overlap</li>
        <li>Times are in seconds from the start of the video</li>
        <li>Playback rates below 1.0 create slow motion effects</li>
        <li>Playback rates above 1.0 create fast motion effects</li>
        <li>Use "Extract from Metadata" for Pixel slow motion videos</li>
      </ul>
    </div>
  </div>