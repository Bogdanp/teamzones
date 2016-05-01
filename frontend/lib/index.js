var moment = require("moment-timezone");

function now() {
  return (new Date).getTime();
}

function seconds() {
  return (new Date).getSeconds();
}

window.moment = moment;
window.init = function(Elm, el, context) {
  context.now = context.timestamps = now();

  var app = Elm.embed(Elm.Main, el, context);
  var sendTimestamp = function() {
    app.ports.timestamps.send(now());
  };

  setTimeout(function() {
    setInterval(1000, sendTimestamp);

    sendTimestamp();
  }, (60 - seconds()) * 1000);
};
