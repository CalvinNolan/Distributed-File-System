const initialState = {files: [], newWrite: false, fileMessages: [], locks: []};

const file = (state = initialState, action) => {
  switch (action.type) {
    case 'FETCH_FILES':
      return {
        files: action.files,
        newWrite: false,
        fileMessages: action.fileMessages,
        locks: action.locks
      }
    case 'WRITE_FILE':
      return {
        files: action.files,
        newWrite: true,
        fileMessages: action.fileMessages,
        locks: action.locks
      }
    case 'RESET_FILES':
      return initialState
    default:
      return state
  }
}

export default file
