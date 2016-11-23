@TagLink = React.createClass

  render: ->
    <Link className={@props.className} href={"/tags/#{@props.tag.id}/#{encodeURI @props.tag.label}"}>
      <Tag tag={@props.tag} />
    </Link>
