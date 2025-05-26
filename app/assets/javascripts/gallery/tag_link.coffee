component 'TagLink', ({className, tag}) ->
  <Link className={className} href={"/tags/#{tag.id}/#{encodeURI(tag.alias || tag.label)}"}>
    <Tag tag={tag}/>
  </Link>
