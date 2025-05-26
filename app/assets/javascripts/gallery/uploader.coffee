class @Uploader
  MAX_CONCURRENT_UPLOADS = 4
  CHUNK_SIZE = 1 * 1024 * 1024

  constructor: (props) ->
    @props = props
    @queue = []
    @deviceToken = localStorage.getItem('deviceToken')
    @manifest = []
    @pathsToHash = []
    @hashedPaths = []
    @pathsToUpload = []
    @currentHashingCount = 0
    @currentUploadingCount = 0

  fileInfoByPath: (path) ->
    file = @queue.find (f) -> f.path == path
    if !file
      throw new Error('File not found')
    file

  addFiles: (files) ->
    newFiles = Array.from(files).map (file) =>
      id: Math.random().toString(36).substr(2, 9)
      file: file
      progress: 0
      status: 'Queued'
      error: null
      path: file.webkitRelativePath || file.name
      mtime: file.lastModified
      size: file.size

    @queue = @queue.concat newFiles
    newFiles.forEach (file) =>
      @props.onQueued? file

    if !@deviceToken
      @authenticate()
    @sendManifest()

  authenticate: ->

    @props.onGlobalStatus? 'Authenticating...'
    try
      res = await fetch('/files/auth',
        method: 'POST'
        headers:
          'Content-Type': 'application/json'
          'X-API-Version': '1.0'
        body: JSON.stringify(
          nickname: navigator.userAgent
          os: navigator.platform
          client_software: 'web'
          client_version: '1.0'
        )
      )

      if !res.ok
        errorText = await res.text()
        throw new Error("Authentication failed: #{res.status} #{errorText}")

      data = await res.json()
      localStorage.setItem('deviceToken', data.token)
      @deviceToken = data.token
    catch error
      console.error('Authentication failed:', error)
      @props.onGlobalError? "Authentication failed: #{error.message}"
      @updateFileProgress(null, 0, 'Error', 'Authentication failed')

  sendManifest: ->
    @props.onGlobalStatus? 'Sending file list...'
    manifest = @queue.map (file) =>
      path: file.path
      mtime: file.mtime
      size: file.size

    try
      res = await fetch('/files/manifest',
        method: 'POST'
        headers:
          'Content-Type': 'application/json'
          'X-API-Version': '1.0'
          'Authorization': "Bearer #{@deviceToken}"
        body: JSON.stringify(manifest)
      )

      if !res.ok
        errorText = await res.text()
        throw new Error "Manifest failed: #{res.status} #{errorText}"

      data = await res.json()

      allPaths = new Set(manifest.map((f) -> f.path))
      toHashPaths = new Set(data.map((f) -> f.path))
      notChangedPaths = allPaths.difference toHashPaths

      # Update status for files that don't need processing
      notChangedPaths.forEach (path) =>
        @updateFileProgress path, 100, 'Not changed'

      @pathsToHash = data.map (file) -> file.path
      @processHashes()
    catch error
      console.error 'Manifest failed:', error
      @props.onGlobalError? "Failed to prepare file manifest: #{error.message}"
      @updateFileProgress null, 0, 'Error', 'Manifest preparation failed'

  processHashes: ->
    if @pathsToHash.length == 0
      @props.onGlobalStatus? 'No new files'
      return

    @props.onGlobalStatus? "Calculating file hashes (#{@pathsToHash.length} files remaining)..."
    @hashNext()

  hashNext: ->
    # Exit if we're already hashing max files or no more files to hash
    if @currentHashingCount >= MAX_CONCURRENT_UPLOADS || @pathsToHash.length == 0
      # If we're done hashing everything, send to server
      if @currentHashingCount == 0 && @pathsToHash.length == 0
        if @hashedPaths.length > 0
          @sendHashesToServer()
        else
          @props.onGlobalStatus? 'All files already existed on server'
      return

    # Get next file to hash
    path = @pathsToHash.shift()

    @currentHashingCount += 1

    @calculateFileHash(path)
      .then (sha256) =>
        fileInfo = @fileInfoByPath path
        fileInfo.sha256 = sha256
        @hashedPaths.push path
      .catch (error) =>
        console.error 'File hash failed:', error
        @props.onGlobalError? "Failed to hash file: #{error.message}"
        @updateFileProgress null, 0, 'Error', 'File hash failed'
      .finally =>
        @currentHashingCount -= 1
        @hashNext()

    @hashNext()

  sendHashesToServer: ->
    try
      hashesToSend = @hashedPaths.map (path) =>
        fileInfo = @fileInfoByPath path
        {
          path: fileInfo.path
          mtime: fileInfo.mtime
          size: fileInfo.size
          sha256: fileInfo.sha256
        }

      response = await fetch('/files/hashes',
        method: 'POST'
        headers:
          'Content-Type': 'application/json'
          'X-API-Version': '1.0'
          'Authorization': "Bearer #{@deviceToken}"
        body: JSON.stringify(hashesToSend)
      )

      if !response.ok
        errorText = await response.text()
        throw new Error "Hash verification failed: #{response.status} #{errorText}"

      data = await response.json()

      # Calculate files that don't need uploading
      allPaths = new Set @queue.map((f) -> f.path)
      toUploadPaths = new Set data.map((f) -> f.path)
      alreadyOnServerPaths = allPaths.difference toUploadPaths

      # Update status for files that don't need uploading
      alreadyOnServerPaths.forEach (path) =>
        @updateFileProgress path, 100, 'Already on server'

      @pathsToUpload = data.map (file) -> file.path
      @processUploads()
    catch error
      console.error 'Hash processing failed:', error
      @props.onGlobalError? "Failed to process file hashes: #{error.message}"
      @updateFileProgress null, 0, 'Error', 'Hash processing failed'

  calculateFileHash: (path) ->
    new Promise (resolve, reject) =>
      fileInfo = @fileInfoByPath path
      file = fileInfo.file

      reader = new FileReader
      chunks = Math.ceil file.size / CHUNK_SIZE
      currentChunk = 0
      sha256 = await createSHA256()

      reader.onload = (e) =>
        buffer = e.target.result
        sha256.update new Uint8Array(buffer)
        currentChunk++

        # Update progress for this file
        progress = Math.round (currentChunk / chunks) * 100
        @updateFileProgress fileInfo.path, progress, 'Hashing...'

        if currentChunk < chunks
          # Read next chunk
          start = currentChunk * CHUNK_SIZE
          end = Math.min start + CHUNK_SIZE, file.size
          reader.readAsArrayBuffer file.slice(start, end)
        else
          # All chunks processed, finalize hash
          hashHex = sha256.digest 'hex'
          resolve hashHex

      # Start reading first chunk
      reader.readAsArrayBuffer file.slice(0, CHUNK_SIZE)

  processUploads: ->
    if @pathsToUpload.length == 0
      @props.onGlobalStatus? 'All files already existed on server'
      return

    @uploadNext()

  uploadNext: ->
    @props.onGlobalStatus? "Uploading files (#{@pathsToUpload.length} files remaining)..."
    if @currentUploadingCount >= MAX_CONCURRENT_UPLOADS || @pathsToUpload.length == 0
      return

    path = @pathsToUpload.shift()

    @currentUploadingCount += 1

    @uploadFile(path)
      .catch (error) =>
        console.error 'File upload failed:', error
        @props.onGlobalError? "Failed to upload file: #{error.message}"
        @updateFileProgress null, 0, 'Error', 'File upload failed'
      .finally =>
        @currentUploadingCount -= 1
        @uploadNext()

    @uploadNext()

  uploadFile: (path) ->
    new Promise (resolve, reject) =>
      fileInfo = @fileInfoByPath path
      file = fileInfo.file

      reader = new FileReader

      reader.onload = (e) =>
        data = e.target.result
        xhr = new XMLHttpRequest

        xhr.upload.addEventListener 'progress', (e) =>
          if e.lengthComputable
            progress = Math.round (e.loaded * 100) / e.total
            @updateFileProgress fileInfo.path, progress, 'Uploading...'

        xhr.addEventListener 'error', (e) =>
          @updateFileProgress fileInfo.path, 0, 'Error', e.target.statusText
          reject e.target.statusText

        xhr.addEventListener 'load', (e) =>
          if e.target.status >= 200 && e.target.status < 300
            @updateFileProgress fileInfo.path, 100, 'Complete'
            resolve()
          else
            errorMsg = e.target.responseText || e.target.statusText
            @updateFileProgress fileInfo.path, 0, 'Error', errorMsg
            reject errorMsg

        xhr.open 'PUT', '/files/upload', true
        xhr.setRequestHeader 'X-API-Version', '1.0'
        xhr.setRequestHeader 'Authorization', "Bearer #{@deviceToken}"
        xhr.setRequestHeader 'X-Path', fileInfo.path
        xhr.setRequestHeader 'X-MTime', fileInfo.mtime
        xhr.setRequestHeader 'X-SHA256', fileInfo.sha256
        xhr.setRequestHeader 'X-Size', fileInfo.size
        xhr.send data

      reader.readAsArrayBuffer(file)

  updateFileProgress: (path, progress, status, error = null) ->
    fileInfo = @fileInfoByPath path
    fileInfo.progress = progress
    fileInfo.status = status
    fileInfo.error = error

    if error
      @props.onError? fileInfo, error
    else if progress == 100
      @props.onComplete? fileInfo
    else
      @props.onProgress? fileInfo, progress
