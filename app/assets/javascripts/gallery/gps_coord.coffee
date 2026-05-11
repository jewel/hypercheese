component 'GPSCoord', ({latitude, longitude}) ->
  return null unless Number.isFinite(latitude) && Number.isFinite(longitude)

  lat = latitude.toFixed 7
  lon = longitude.toFixed 7
  url = "https://www.google.com/maps?ll=#{lat},#{lon}&q=#{lat},#{lon}&hl=en&t=m&z=12"
  <React.Fragment>
    <a href={url} target="_blank">{lat}, {lon}</a>
    {" "}
    <span>
      Photos within:
      {" "}
      {
        [10, 100, 1000].map (meters, i) ->
          query = "near:#{lat},#{lon} radius:#{meters}"
          href = "/search/" + encodeURI(query)
          <React.Fragment key={meters}>
            <Link href={href}>{meters}m</Link>
            {if i < 2 then " " else null}
          </React.Fragment>
      }
    </span>
  </React.Fragment>

