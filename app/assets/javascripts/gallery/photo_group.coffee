component 'PhotoGroup', ({group}) ->
  getPhotoCount = ->
    screenWidth = window.innerWidth
    if screenWidth <= 480
      photoWidth = 54  # 50px + 4px margin
    else if screenWidth <= 768
      photoWidth = 64  # 60px + 4px margin
    else
      photoWidth = 84  # 80px + 4px margin

    screenWidth -= 16 * 2 # margin

    maxPhotos = Math.floor screenWidth / photoWidth
    Math.min maxPhotos, group.id_samples.length

  [photoCount, setPhotoCount] = useState getPhotoCount()

  useEffect ->
    handleResize = ->
      setPhotoCount getPhotoCount()

    window.addEventListener 'resize', handleResize
    -> window.removeEventListener 'resize', handleResize
  , []

  itemsToShow = group.id_samples.slice 0, photoCount

  <div className="photo-group">
    {
      itemsToShow.map (sample) ->
        id = sample.id
        code = sample.code

        <Link key={id} href="/items/#{id}" className="photo-group-item">
          <ItemImg id={id} code={code} size="square" />
        </Link>
    }
  </div>
