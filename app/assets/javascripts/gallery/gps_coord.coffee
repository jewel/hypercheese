@GPSCoord = createReactClass
  r: (frac) ->
    parts = frac.split "/"
    n = parseInt parts[0], 10
    d = parseInt parts[1], 10
    n / d

  coord: (input) ->
    c = @r(input[0]) + @r(input[1])/60 + @r(input[2])/3600
    c.toFixed 7

  render: ->
    e = @props.exif
    return null unless e
    return null unless e.gps_latitude && e.gps_longitude
    lat = @coord e.gps_latitude
    lat *= -1 if e.gps_latitude_ref == "S"
    lon = @coord e.gps_longitude
    lon *= -1 if e.gps_longitude_ref == "W"
    url = "https://www.google.com/maps?ll=#{lat},#{lon}&q=#{lat},#{lon}&hl=en&t=m&z=12"
    <a href={url} target="_blank">{lat}, {lon}</a>

