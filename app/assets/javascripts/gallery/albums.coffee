component 'Albums', ->
  [albums, setAlbums] = useState []
  [loading, setLoading] = useState true

  useEffect ->
    fetchAlbums()
  , []

  fetchAlbums = ->
    setLoading true
    Store.jax
      url: '/api/albums'
      success: (res) ->
        setAlbums res.albums
        setLoading false

  shareAlbum = (album) ->
    Store.shareAlbum(album.id).then (url) ->
      window.prompt "The album is available at this link:", url

  if loading
    return <div className="loading">Loading albums...</div>

  <div className="albums-container">
    <div className="container">
      <div className="row">
        <div className="col-12">
          <h1>Albums</h1>
          
          {
            if albums.length == 0
              <div className="empty-state">
                <p>No albums yet. Create your first album by selecting some photos and using the "Add to Album" button.</p>
              </div>
            else
              <div className="albums-grid">
                {
                  albums.map (album) ->
                    firstItem = album.items?[0]
                    coverImage = if firstItem
                      Store.resizedURL 'large', firstItem.id, firstItem.code
                    else
                      '/images/album-placeholder.jpg'

                    <div key={album.id} className="album-card">
                      <div className="album-cover">
                        <img src={coverImage} alt={album.name} />
                        <div className="album-overlay">
                          <button 
                            className="btn btn-primary btn-sm"
                            onClick={ -> shareAlbum(album) }
                          >
                            <i className="fa fa-share-alt"/> Share
                          </button>
                        </div>
                      </div>
                      <div className="album-info">
                        <h5>{album.name}</h5>
                        {
                          if album.description
                            <p className="album-description">{album.description}</p>
                        }
                        <div className="album-meta">
                          <span className="item-count">
                            {album.item_count} item{if album.item_count != 1 then 's' else ''}
                          </span>
                          <span className="album-owner">by {album.user.name || album.user.username}</span>
                        </div>
                      </div>
                    </div>
                }
              </div>
          }
        </div>
      </div>
    </div>
  </div>