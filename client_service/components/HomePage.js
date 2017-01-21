import React from 'react'
import FileSystemContainer from '../containers/FileSystemContainer';

const HomePage = React.createClass({
  propTypes: {
    isLoggedIn: React.PropTypes.bool.isRequired,
    username: React.PropTypes.string,
    userId: React.PropTypes.number,
    message: React.PropTypes.string,
    token: React.PropTypes.string,

    signUp: React.PropTypes.func.isRequired,
    authStatus: React.PropTypes.func.isRequired,
    logOut: React.PropTypes.func.isRequired,
    logIn: React.PropTypes.func.isRequired
  },

  componentWillMount() {
    this.props.authStatus();
  },

  signUp() {
    if (this.refs.signUpUsername.value !== '' && this.refs.signUpPassword.value !== '') {
      this.props.signUp(this.refs.signUpUsername.value, this.refs.signUpPassword.value);
    }
  },

  logIn() {
    if (this.refs.logInUsername.value !== '' && this.refs.logInPassword.value !== '') {
      this.props.logIn(this.refs.logInUsername.value, this.refs.logInPassword.value);
    }
  },

  render() {
    const homeStyle = require("../styles/Homepage.scss");
    const style = require("../styles/App.scss");
    return (
      <div className="centerBox">
          <h2>Distributed File System</h2>
          { !this.props.isLoggedIn
              ? <span>
                  <div>
                    <h3>Sign Up</h3>
                    <input type="text" ref="signUpUsername" placeholder="username" />
                    <input type="password" ref="signUpPassword" placeholder="password" />

                    <div className="button" onClick={this.signUp}>
                      <p className="noselect">SIGN UP</p>
                    </div>
                  </div>
                  <div>
                    <h3>Log In</h3>
                    <input type="text" ref="logInUsername" placeholder="username" />
                    <input type="password" ref="logInPassword" placeholder="password" />

                    <div className="button" onClick={this.logIn}>
                      <p className="noselect">LOG IN</p>
                    </div>
                  </div>
                </span>
              : <span>
                  <p className="userWelcome">Welcome, <span className="username">{this.props.username}</span></p>
                  <p className="userToken">Auth Token: <span className="token">{this.props.token}</span></p>
                  <div className="button" onClick={this.props.logOut}>
                    <p className="noselect">LOG OUT</p>
                  </div>
                  <hr/>
                  <FileSystemContainer />
                </span>
          }
      </div>
    );
  }
});

export default HomePage

