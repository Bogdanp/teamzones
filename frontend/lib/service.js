require("whatwg-fetch");

function request(endpoint, userOptions) {
  var options = {
    credentials: "same-origin"
  };

  if (typeof userOptions !== "undefined") {
    for (var key in options) {
      options[key] = userOptions[key];
    }
  }

  return fetch("/api/" + endpoint, options).then(function(response) {
    if (response.status < 400) {
      return response.json();
    }

    var error = new Error(response.statusText);
    error.response = response;
    throw error;
  });
}

function fetchBraintreeToken() {
  return request("bt-token");
}

function fetchLocation() {
  return request("location");
}

module.exports = {
  fetchBraintreeToken: fetchBraintreeToken,
  fetchLocation: fetchLocation
};
