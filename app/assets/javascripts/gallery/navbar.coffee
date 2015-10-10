@NavBar = React.createClass
  render: ->
    <nav className="navbar navbar-default">
      <div className="container-fluid">
        <a className="navbar-brand">HyperCheese</a>
        <ul className="nav navbar-nav navbar-right">
          <li>
            <a href="/users/sign_out" data-method="delete" rel="nofollow">Sign out</a>
          </li>
          <li>
            <a href="http://www.rickety.us/sundry/hypercheese-help/">Help</a>
          </li>
        </ul>
      </div>
    </nav>
