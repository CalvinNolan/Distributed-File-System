import React from 'react'

const ListedFile = React.createClass({
  propTypes: {
    filename: React.PropTypes.string.isRequired,
    file_id: React.PropTypes.number.isRequired,
    user_id: React.PropTypes.number.isRequired,
    owner: React.PropTypes.string.isRequired,
    owner_id: React.PropTypes.number.isRequired,
    updated_time: React.PropTypes.string.isRequired,
    username: React.PropTypes.string.isRequired,
    token: React.PropTypes.string.isRequired,
    shareFile: React.PropTypes.func.isRequired,
    readFile: React.PropTypes.func.isRequired,
    file_message: React.PropTypes.string.isRequired,
    file_messages: React.PropTypes.array.isRequired,
    files: React.PropTypes.array.isRequired,
    lockFile: React.PropTypes.func.isRequired,
    unlockFile: React.PropTypes.func.isRequired,
    updateFile: React.PropTypes.func.isRequired,
    lock: React.PropTypes.string.isRequired,
    locks: React.PropTypes.array.isRequired
  },

  shareFile(e) {
    e.preventDefault();
    if (this.refs.shareFileUsername.value !== "") {
      this.props.shareFile(this.props.username, this.props.token, 
                            this.refs.shareFileUsername.value, this.props.file_id, 
                              this.props.file_messages, this.props.files, this.props.locks);
    }
  },

  readFile() {
    this.props.readFile(this.props.username, this.props.token,
                          this.props.file_id, this.props.filename, 
                            this.props.files, this.props.file_messages);
  },

  lockFile() {
    console.log(this.props.files);
    this.props.lockFile(this.props.username, this.props.token,
                          this.props.file_id, this.props.file_messages, 
                            this.props.files, this.props.locks);
  },

  unlockFile() {
    this.props.unlockFile(this.props.username, this.props.token, 
                            this.props.file_id, this.props.file_messages, 
                              this.props.files, this.props.locks);
  },

  updateFile(e) {
    e.preventDefault();
    this.props.updateFile(this.props.username, this.props.token, 
                            this.props.lock, this.props.file_id, 
                              this.refs.userFile.files, this.props.files, 
                                this.props.file_messages, this.props.locks);
  },

  render() {
    var date = new Date(this.props.updated_time);
    return (
      <li className="listedFile">
        <span>
          <p className="fileTitle" onClick={this.readFile}>{this.props.filename}</p>
          <div className="ownerDate">
            <p className="ownerName">Owner: <span className="owner">{this.props.owner}</span></p>
            <p className="dateUpdated">Updated: <span className="owner">{date.toString()}</span></p>
          </div> 
          {
            this.props.file_message !== "" &&
              <p className="fileMessage">{ this.props.file_message }</p>
          }
        </span>
        { this.props.user_id == this.props.owner_id &&
            <span>
              <hr/>
              <h4>SHARE FILE</h4>
              <form>
                <input type="text" ref="shareFileUsername" placeholder="username"></input>
                <input type="submit" onClick={this.shareFile} value="Share"></input>
              </form>
            </span>
        }
        <hr/>
        <span>
          <h4>UPDATE FILE</h4>
          <form onSubmit={this.updateFile} method='POST'>
              <input type='file' ref='userFile'></input>
              <input type='submit'></input>
          </form>
        </span>
        { this.props.lock === ""
          ? <div className="button" onClick={this.lockFile}>
              <p className="noselect">LOCK</p>
            </div>
          : <span>
              <p className="userToken">Lock Token: <span className="token">{this.props.lock}</span></p>
              <div className="button" onClick={this.unlockFile}>
                <p className="noselect">UNLOCK</p>
              </div>
            </span>
        }
      </li>
    );
  }
});

export default ListedFile;

