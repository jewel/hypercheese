@SearchHelper = React.createClass
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
      <form onSubmit={(e) -> e.preventDefault()} className="form-inline">
        {'Find '}
        {
          @optionHelper 'variety',
            ['', 'photos and videos']
            ['photo', 'photos']
            ['videos', 'videos']
        }
        {' of '}
        {@props.tags || 'everything'}
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
        <button className="btn btn-default btn-primary">
          <i className="fa fa-search"/>
        </button>
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
