import { connect } from 'react-redux';
import { signUp, authStatus, logOut, logIn } from '../actions/auth';
import HomePage from '../components/HomePage';

const mapStateToProps = (state) => {
  return {
    isLoggedIn: state.auth.loggedIn,
    username: state.auth.username,
    userId: state.auth.userId,
    message: state.auth.error,
    token: state.auth.token
  }
};

const mapDispatchToProps = (dispatch) => {
  return {
    signUp: (username, password) => {
      dispatch(signUp(username, password));
    },
    authStatus: () => {
      dispatch(authStatus());
    },
    logOut: () => {
      dispatch(logOut());
    },
    logIn: (username, password) => {
      dispatch(logIn(username, password));
    }
  };
};

const HomePageContainer = connect(mapStateToProps, mapDispatchToProps)(HomePage);

export default HomePageContainer;