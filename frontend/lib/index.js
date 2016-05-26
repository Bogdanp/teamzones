var moment = require("moment-timezone");

var Checkout = require("./checkout");
var service = require("./service");

function now() {
  return (new Date).getTime();
}

function seconds() {
  return (new Date).getSeconds();
}

window.moment = moment;
window.Checkout = Checkout;
window.init = function(Elm, el, context) {
  context.now = now();
  context.user.integrations = context.integrations;
  context.timezones = moment.tz.names().filter(function(tz) {
    return tz.indexOf("/") !== -1 && tz.indexOf("Etc/") !== 0;
  });

  var app = Elm.Main.embed(el, context);

  // Time{zone,stamp} subs
  service.fetchLocation().then(function(location) {
    if (location.timezone && location.timezone !== context.user.timezone) {
      app.ports.timezones.send(location.timezone);
    }
  });

  // Notifications
  app.ports.notify.subscribe(function(message) {
    app.ports.notifications.send(message);
  });

  var sendTimestamp = function() {
    app.ports.timestamps.send(now());
  };

  setTimeout(function() {
    setInterval(sendTimestamp, 60000);

    sendTimestamp();
  }, (60 - seconds()) * 1000);
};
