const initialState = {loggedIn: false, username: '', userId: -1, token: '', message: ''};

const auth = (state = initialState, action) => {
  switch (action.type) {
    case 'LOG_IN':
      return {
        loggedIn: true,
        username: action.username,
        userId: action.userId,
        token: action.token,
        message: ''
      }
    case 'ERROR_LOG_IN':
      return {
        loggedIn: false,
        username: '',
        userId: '',
        token: '',
        message: action.error
      }
    case 'LOG_OUT':
      return initialState
    default:
      return state
  }
}

export default auth
