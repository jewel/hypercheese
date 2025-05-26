component 'Tag', ({tag, label, selected, onClick, children}) ->
  tagIconURL = Store.resizedURL "square", tag.icon_id, tag.icon_code

  classes = ['tag']
  classes.push 'selected' if selected

  <div className={classes.join ' '} onClick={onClick}>
    <img title={tag.alias || tag.label} className="tag-icon" src={tagIconURL}/>
    {
      if label
        <div>{tag.alias || tag.label}</div>
    }
    {children}
  </div>
