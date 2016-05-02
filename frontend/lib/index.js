var moment = require("moment-timezone");
var service = require("./service");

function now() {
  return (new Date).getTime();
}

function seconds() {
  return (new Date).getSeconds();
}

window.moment = moment;
window.init = function(Elm, el, context) {
  context.now = context.timestamps = now();
  context.timezones = context.user.timezone;
  context.path = window.location.pathname;

  var app = Elm.embed(Elm.Main, el, context);
  var sendTimestamp = function() {
    app.ports.timestamps.send(now());
  };

  service.fetchLocation().then(function(location) {
    if (location.timezone && location.timezone !== context.user.timezone) {
      app.ports.timezones.send(location.timezone);
    }
  });

  setTimeout(function() {
    setInterval(sendTimestamp, 60000);

    sendTimestamp();
  }, (60 - seconds()) * 1000);
};
