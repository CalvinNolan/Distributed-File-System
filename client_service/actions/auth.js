import $ from 'jquery';

export function signUp (username, password) {
  return function (dispatch) {
    let data = {
      username,
      password
    };
    data = encrypt_request(data);
    $.ajax({
      type: "POST",
      url: "http://localhost:3020/signup",
      data: {
        data
      },
      xhrFields: {
        withCredentials: true
      },
      success: function(response) {
        response = decrypt_response(response);
        if (response.result) {
          dispatch({ type: 'LOG_IN', username: response.username, userId: response.user_id, token: response.token });
        }
      }
    });
  };
};

export function authStatus () {
  return function (dispatch) {
    $.ajax({
      type: "GET",
      url: "http://localhost:3020/status",
      xhrFields: {
        withCredentials: true
      },
      success: function(response) {
        response = decrypt_response(response);
        if (response.result) {
          dispatch({ type: 'LOG_IN', username: response.username, userId: response.user_id, token: response.token });
        }
      }
    });
  };
};

export function logOut () {
  return function (dispatch) {
    $.ajax({
      type: "POST",
      url: "http://localhost:3020/logout",
      xhrFields: {
        withCredentials: true
      },
      success: function(response) {
        response = decrypt_response(response);
        if (response.result) {
          dispatch({ type: 'LOG_OUT' });
        }
      }
    });
  };
};

export function logIn (username, password) {
  return function (dispatch) {
    let data = {
      username,
      password
    };
    data = encrypt_request(data);
    $.ajax({
      type: "POST",
      url: "http://localhost:3020/login",
      data: {
        data
      },
      xhrFields: {
        withCredentials: true
      },
      success: function(response) {
        response = decrypt_response(response);
        if (response.result) {
          dispatch({ type: 'LOG_IN', username: response.username, userId: response.user_id, token: response.token });
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