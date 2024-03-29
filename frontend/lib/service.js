import "whatwg-fetch";

function request(endpoint, userOptions) {
  let options = {
    credentials: "same-origin"
  };

  if (typeof userOptions !== "undefined") {
    for (var key in options) {
      options[key] = userOptions[key];
    }
  }

  return fetch(`/api/${endpoint}`, options).then(response => {
    if (response.status < 400) {
      return response.json();
    }

    var error = new Error(response.statusText);
    error.response = response;
    throw error;
  });
}

export function fetchBraintreeToken() {
  return request("bt-token");
}

export function fetchLocation() {
  return request("location");
}
