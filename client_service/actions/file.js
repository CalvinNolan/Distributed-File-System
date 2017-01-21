import $ from 'jquery';

export function writeFile (username, auth_token, file_data, currentFiles, fileMessages, locks) {
  return function (dispatch) {
    // Create a formdata object and add the files
    var form_data = new FormData();
    form_data.append("file_data", file_data[0]);
    form_data.append("data", encrypt_request({ username, auth_token }));

    $.ajax({
      type: "POST",
      url: "http://localhost:3040/write",
      data: form_data,
      cache: false,
      dataType: 'json',
      processData: false, // Don't process the files
      contentType: false, // Set content type to false as jQuery will tell the server its a query string request
      xhrFields: {
        withCredentials: true
      },
      success: function(response) {
        response = decrypt_response(response);
        dispatch({ type: 'WRITE_FILE', files: currentFiles, fileMessages: fileMessages, locks: locks})
      }
    });
  };
};

export function updateFile (username, auth_token, lock_token, file_id, file_data, currentFiles, fileMessages, locks) {
  return function (dispatch) {
    // Create a formdata object and add the files
    var form_data = new FormData();
    form_data.append("file_data", file_data[0]);
    form_data.append("data", encrypt_request({ username, auth_token, lock_token, file_id }));

    $.ajax({
      type: "POST",
      url: "http://localhost:3040/update",
      data: form_data,
      cache: false,
      dataType: 'json',
      processData: false, // Don't process the files
      contentType: false, // Set content type to false as jQuery will tell the server its a query string request
      xhrFields: {
        withCredentials: true
      },
      success: function(response) {
        response = decrypt_response(response);
        if (response.result) {
          fileMessages[file_id] = "Successfully updated.";
          dispatch({ type: 'FETCH_FILES', files: currentFiles, fileMessages: fileMessages, locks: locks });
        } else {
          fileMessages[file_id] = response.message;
          dispatch({ type: 'FETCH_FILES', files: currentFiles, fileMessages: fileMessages, locks: locks });
        }
      }
    });
  };
};

export function readFile (username, auth_token, file_id, filename, currentFiles, fileMessages) {
  return function (dispatch) {
    var form_data = new FormData();
    form_data.append("data", encrypt_request({ username, auth_token, file_id }));

    // We have to use good old reliable XHR since AJAX doesn't support receiving binary just yet.
    var xhr = new XMLHttpRequest();
    xhr.addEventListener('load', function(){
       if (xhr.status == 200){
          var FileSaver = require('file-saver');
          var blob = new Blob([xhr.response], {type: "application/octet-stream"});
          FileSaver.saveAs(blob, filename);
       }
    });
     
    xhr.open('POST', 'http://localhost:3040/read');
    xhr.responseType = 'blob';
    xhr.send(form_data);
  };
};

export function listFiles (username, auth_token, fileMessages) {
  return function (dispatch) {
    var data = {
      username,
      auth_token
    }

    $.ajax({
      type: "POST",
      url: "http://localhost:3040/all",
      data: {
        data: encrypt_request(data)
      },
      xhrFields: {
        withCredentials: true
      },
      success: function(response) {
        response = decrypt_response(response);
        if (response.result) {
          dispatch({ type: 'FETCH_FILES', files: response.files, fileMessages: fileMessages, locks: response.locks });
        }
      }
    });
  };
};

export function shareFile (username, auth_token, share_username, file_id, fileMessages, currentFiles, locks) {
  return function (dispatch) {
    var data = {
      username,
      auth_token,
      share_username,
      file_id
    }

    $.ajax({
      type: "POST",
      url: "http://localhost:3040/share",
      data: {
        data: encrypt_request(data)
      },
      xhrFields: {
        withCredentials: true
      },
      success: function(response) {
        response = decrypt_response(response);
        if (response.result) {
          fileMessages[file_id] = response.message;
          dispatch({ type: 'FETCH_FILES', files: currentFiles, fileMessages: fileMessages, locks: locks });
        } else if (!response.result) {
            if (typeof(response.message.duplicate_ownership) !== 'undefined') {
              fileMessages[file_id] = "File already shared to that user";
            } else {
              fileMessages[file_id] = response.message;
            }
          dispatch({ type: 'FETCH_FILES', files: currentFiles, fileMessages: fileMessages, locks: locks });
        }
      }
    });
  };
};

export function lockFile (username, auth_token, file_id, fileMessages, currentFiles, locks) {
  return function (dispatch) {
    var data = {
      username,
      auth_token,
      file_id
    }

    $.ajax({
      type: "POST",
      url: "http://localhost:3050/lock",
      data: {
        data: encrypt_request(data)
      },
      xhrFields: {
        withCredentials: true
      },
      success: function(response) {
        response = decrypt_response(response);
        if (response.result) {
          dispatch({ type: 'FETCH_FILES', files: currentFiles, fileMessages: fileMessages, locks: response.locks });
        } else {
          fileMessages[file_id] = response.message;
          dispatch({ type: 'FETCH_FILES', files: currentFiles, fileMessages: fileMessages, locks: locks });
        }
      }
    });
  };
};

export function unlockFile (username, auth_token, file_id, fileMessages, currentFiles, locks) {
  return function (dispatch) {
    var data = {
      username,
      auth_token,
      file_id
    }

    $.ajax({
      type: "POST",
      url: "http://localhost:3050/unlock",
      data: {
        data: encrypt_request(data)
      },
      xhrFields: {
        withCredentials: true
      },
      success: function(response) {
        response = decrypt_response(response);
        if (response.result) {
          dispatch({ type: 'FETCH_FILES', files: currentFiles, fileMessages: fileMessages, locks: response.locks });
        } else {
          fileMessages[file_id] = response.message;
          dispatch({ type: 'FETCH_FILES', files: currentFiles, fileMessages: fileMessages, locks: locks });
        }
      }
    });
  };
};

function decrypt_response(response) {
  return JSON.parse(Buffer.from(response, 'base64').toString());
}

function encrypt_request(response) {
  return Buffer(JSON.stringify(response)).toString("base64");
}