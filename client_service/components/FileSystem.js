import React from 'react'
import ListedFile from './ListedFile';

const FileSystem = React.createClass({
  propTypes: {
    username: React.PropTypes.string.isRequired,
    token: React.PropTypes.string.isRequired,
    files: React.PropTypes.array.isRequired,
    newWrite: React.PropTypes.bool.isRequired,
    fileMessages: React.PropTypes.array.isRequired,
    locks: React.PropTypes.array.isRequired,

    writeFile: React.PropTypes.func.isRequired,
    listFiles: React.PropTypes.func.isRequired,
    shareFile: React.PropTypes.func.isRequired,
    readFile: React.PropTypes.func.isRequired,
    lockFile: React.PropTypes.func.isRequired,
    unlockFile: React.PropTypes.func.isRequired,
    updateFile: React.PropTypes.func.isRequired
  },

  componentWillMount() {
    this.props.listFiles(this.props.username, this.props.token, this.props.fileMessages);
  },

  componentDidUpdate() {
    if (this.props.newWrite) {
      this.props.listFiles(this.props.username, this.props.token, this.props.fileMessages);
    }
  },

  writeFile(e) {
    e.preventDefault();
    this.props.writeFile(this.props.username, this.props.token, this.refs.userFile.files, this.props.files, this.props.fileMessages, this.props.locks);
  },

  renderFiles(files) {
    var fileList = [];
    files.forEach(file => {
      var fileMessage = typeof(this.props.fileMessages[file.id]) === 'undefined' ? "" : this.props.fileMessages[file.id];
      var fileLock = "";
      this.props.locks.forEach(lock => {
        if (lock.directory_file_id === file.id) {
          fileLock = lock.lock_token;
        }
      });
      fileList.push(
        <ListedFile 
          key={file.filename}
          filename={file.filename}
          files={this.props.files}
          file_id={file.id}
          file_message={fileMessage}
          file_messages={this.props.fileMessages}
          owner={file.owner_name}
          owner_id={file.owner_id}
          user_id={file.uid}
          updated_time={file.updated_at}
          username={this.props.username}
          token={this.props.token}
          shareFile={this.props.shareFile}
          readFile={this.props.readFile}
          lockFile={this.props.lockFile}
          unlockFile={this.props.unlockFile}
          updateFile={this.props.updateFile}
          lock={fileLock}
          locks={this.props.locks}
        />
      );
    });
    return(<ul className="fileList">{fileList}</ul>);
  },

  render() {
    const styles = require("../styles/App.scss");
    return (
      <div>
        <h3>UPLOAD A NEW FILE</h3>
        <form onSubmit={this.writeFile} method='POST'>
            <input type='file' ref='userFile'></input>
            <input type='submit'></input>
        </form>

        <hr/>

        <h3>YOUR FILES</h3>
        { this.props.files.length > 0
            ? this.renderFiles(this.props.files) 
            : <p className="nofiles">You currently have no files.</p>
        }
      </div>
    );
  }
});

export default FileSystem;

