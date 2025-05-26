component 'ControlIcon', ({condition, icon, active, title, className, href, onClick}) ->
  return null if condition? && !condition
  iconClasses = "fa fa-fw #{icon}"
  iconClasses += " active" if active

  <a
    title={title}
    className="control #{className}"
    href={href || "#!"}
    onClick={onClick}
  >
    <i className={iconClasses}></i>
  </a>

