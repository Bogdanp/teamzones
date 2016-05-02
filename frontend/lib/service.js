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

  return fetch("/api/v1/" + endpoint, options).then(function(response) {
    if (response.status < 400) {
      return response.json();
    }

    var error = new Error(response.statusText);
    error.response = response;
    throw error;
  });
}

function fetchLocation() {
  return request("location");
}

module.exports = {
  fetchLocation: fetchLocation
};
