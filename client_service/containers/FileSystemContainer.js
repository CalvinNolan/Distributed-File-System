import { connect } from 'react-redux';
import { writeFile, listFiles, shareFile, readFile, lockFile, unlockFile, updateFile } from '../actions/file';
import FileSystem from '../components/FileSystem';

const mapStateToProps = (state) => {
  return {
    username: state.auth.username,
    token: state.auth.token,
    files: state.file.files,
    newWrite: state.file.newWrite,
    fileMessages: state.file.fileMessages.slice(),
    locks: state.file.locks.slice()
  }
};

const mapDispatchToProps = (dispatch) => {
  return {
    writeFile: (username, token, file_data, currentFiles, fileMessages, locks) => {
      dispatch(writeFile(username, token, file_data, currentFiles, fileMessages, locks));
    },
    listFiles: (username, token, fileMessages) => {
      dispatch(listFiles(username, token, fileMessages));
    },
    shareFile: (username, token, share_username, file_id, fileMessages, currentFiles, locks) => {
      dispatch(shareFile(username, token, share_username, file_id, fileMessages, currentFiles, locks));
    },
    readFile: (username, token, file_id, filename, currentFiles, fileMessages) => {
      dispatch(readFile(username, token, file_id, filename, currentFiles, fileMessages));
    },
    lockFile: (username, token, file_id, fileMessages, currentFiles, locks) => {
      dispatch(lockFile(username, token, file_id, fileMessages, currentFiles, locks));
    },
    unlockFile: (username, token, file_id, fileMessages, currentFiles, locks) => {
      dispatch(unlockFile(username, token, file_id, fileMessages, currentFiles, locks));
    },
    updateFile: (username, auth_token, lock_token, file_id, file_data, currentFiles, fileMessages, locks) => {
      dispatch(updateFile(username, auth_token, lock_token, file_id, file_data, currentFiles, fileMessages, locks));
    }
  };
};

const FileSystemContainer = connect(mapStateToProps, mapDispatchToProps)(FileSystem);

export default FileSystemContainer;