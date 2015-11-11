@SearchHelper = React.createClass
  getInitialState: ->
    newSearch: Store.state.query

  changeNewSearch: (e) ->
    @setState
      newSearch: e.target.value

  updateSearch: (str) ->
    @setState
      newSearch: str

  onSearch: (e) ->
    e.preventDefault()
    @props.close()
    window.location.hash = '/search/' + encodeURI(@state.newSearch)

  optionHelper: (field, options...) ->
    val = ""
    <select className="form-control" defaultValue={val}>
      {
        options.map (opt) =>
          <option key={opt[0]} value={opt[0]}>{opt[1]}</option>
      }
    </select>

  render: ->
    <div className="search-helper">
      <form onSubmit={@onSearch} className="form-inline">
        <input className="form-control" placeholder="Search" defaultValue={Store.state.query} value={@state.newSearch} onChange={@changeNewSearch} type="text"/>
        {'Find '}
        {
          @optionHelper 'variety',
            ['', 'photos and videos']
            ['photo', 'photos']
            ['videos', 'videos']
        }
        {' of '}
        {@props.tags || 'everything'}
        {' uploaded by '}
        {
          @optionHelper 'source',
            ['', 'anyone']
            ['jill', 'Jill']
            ['rick', 'Rick']
        }
        {' from '}
        {
          @optionHelper 'month',
            ['', 'all months']
            ['spring', 'spring']
            ['summer', 'summer']
            ['fall', 'fall']
            ['winter', 'winter']
            ['jan', 'January']
            ['feb', 'February']
            ['mar', 'March']
            ['apr', 'April']
            ['may', 'May']
            ['jun', 'June']
            ['jul', 'July']
            ['aug', 'August']
            ['sep', 'September']
            ['oct', 'October']
            ['nov', 'November']
            ['dec', 'December']
        }
        {' of '}
        {
          years = [
            ['', 'all years']
            ['<1990', '1989 or before']
            ['1990s', 'the \'90s']
            ['2000s', 'the \'00s']
            ['2010s', 'the \'10s']
          ]

          for year in [1990...2020]
            years.push ["#{year}", "#{year}"]

          @optionHelper 'year', years...
        }
        {', in '}
        {
          @optionHelper 'direction',
            ['', 'order']
            ['reverse', 'reversed order']
        }
        {' '}
        {
          @optionHelper 'order',
            ['', 'by date taken']
            ['id', 'by id']
            ['added', 'by date added']
            ['md5', 'by randomness']
            ['stars', 'by star count']
        }
        {'. '}
      </form>
      <div className="tag-list">
        {
          # FIXME Add "untagged" as the first choice
          Store.state.tags.map (tag) =>
            tagIconURL = "/data/resized/square/#{tag.icon}.jpg"
            <div key={tag.id} className="tag">
              <img className="tag-icon" src={tagIconURL}/><br/>
              {tag.label}
            </div>
        }
      </div>
    </div>
