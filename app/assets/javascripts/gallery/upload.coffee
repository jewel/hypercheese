component 'Upload', ->
  [uploads, setUploads] = useState []
  [uploader, setUploader] = useState null
  [globalStatus, setGlobalStatus] = useState null
  [globalError, setGlobalError] = useState null

  useEffect ->
    setUploader new Uploader
      onQueued: onQueued
      onProgress: onProgress
      onComplete: onComplete
      onError: onError
      onGlobalStatus: onGlobalStatus
      onGlobalError: onGlobalError
    ->
  , []

  onFileSelect = (e) ->
    files = e.target.files
    handleFiles files

  onDirectorySelect = (e) ->
    files = e.target.files
    handleFiles files

  handleFiles = (files) ->
    uploader?.addFiles files

  onQueued = (file) ->
    setUploads uploads.concat [file]

  onProgress = (file, progress) ->
    setUploads uploads.map (upload) ->
      if upload.id == file.id
        {
          ...upload
          progress: progress
          status: 'Uploading...'
        }
      else
        upload

  onComplete = (file) ->
    setUploads uploads.map (upload) ->
      if upload.id == file.id
        {
          ...upload
          progress: 100
          status: 'Complete'
        }
      else
        upload

  onError = (file, error) ->
    setUploads uploads.map (upload) ->
      if upload.id == file.id
        {
          ...upload
          progress: 0
          status: "Error: #{error}"
        }
      else
        upload

  onGlobalStatus = (status) ->
    setGlobalStatus status
    setGlobalError null

  onGlobalError = (error) ->
    setGlobalStatus null
    setGlobalError error

  <div className="upload-page">
    <div className="upload-drop-zone">
      <div className="upload-message">
        <i className="fa fa-cloud-upload fa-3x"/>
        <p>Drag and drop files here</p>
        <p>or</p>
        <div className="upload-buttons">
          <label className="btn btn-primary" htmlFor="file-upload">
            <i className="fa fa-file"/> Upload Files
          </label>
          <label className="btn btn-primary" htmlFor="directory-upload">
            <i className="fa fa-folder"/> Upload Directory
          </label>
        </div>
      </div>
    </div>

    <input
      type="file"
      id="file-upload"
      multiple
      onChange={onFileSelect}
      style={display: 'none'}
    />
    <input
      type="file"
      id="directory-upload"
      webkitdirectory="true"
      directory="true"
      onChange={onDirectorySelect}
      style={display: 'none'}
    />

    {
      if globalStatus || globalError
        <div className="global-status">
          {
            if globalError
              <div className="alert alert-danger">
                <i className="fa fa-exclamation-circle"/> {globalError}
              </div>
            else if globalStatus
              <div className="alert alert-info">
                <i className="fa fa-info-circle"/> {globalStatus}
              </div>
          }
        </div>
    }

    <div className="upload-status">
      {
        uploads.map (upload) ->
          <div key={upload.id} className="upload-item">
            <div className="filename">{upload.file.name}</div>
            <div className="progress">
              <div className="progress-bar" style={width: "#{upload.progress}%"}/>
            </div>
            <div className="status">{upload.status}</div>
          </div>
      }
    </div>
  </div>
