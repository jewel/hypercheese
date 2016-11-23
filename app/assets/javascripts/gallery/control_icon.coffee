@ControlIcon = React.createClass
  render: ->
    return null if @props.condition? && !@props.condition
    iconClasses = "fa fa-fw #{@props.icon}"
    iconClasses += " active" if @props.active
    <a
      title={@props.title}
      className="control #{@props.className}"
      href={@props.href || "javascript:void(0)"}
      onClick={@props.onClick}
    >
      <i className={iconClasses}></i>
    </a>

