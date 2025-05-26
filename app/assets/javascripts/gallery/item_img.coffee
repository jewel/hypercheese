component 'ItemImg', ({size, id, code}) ->
  url = Store.resizedURL size || "square", id, code
  <img src={url} />
