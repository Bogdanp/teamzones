import moment from "moment-timezone";

import Checkout from "./checkout";
import {fetchLocation} from "./service";

function now() {
  return (new Date).getTime();
}

function seconds() {
  return (new Date).getSeconds();
}

window.loadTimezone = function(el) {
  el.value = moment.tz.guess();
  fetchLocation().then(location => {
    if (location.timezone) {
      el.value = location.timezone;
    }
  });
};

window.moment = moment;
window.Checkout = Checkout;
window.init = function(Elm, el, context) {
  context.viewportWidth = window.innerWidth;
  context.now = now();
  context.user.integrations = context.integrations;
  context.timezones = moment.tz.names().filter(tz => {
    return tz.indexOf("/") !== -1 && tz.indexOf("Etc/") !== 0;
  });

  const app = Elm.Main.embed(el, context);

  // Time{zone,stamp} subs
  fetchLocation().then(location => {
    if (location.timezone && location.timezone !== context.user.timezone) {
      app.ports.timezones.send(location.timezone);
    }
  });

  // Notifications
  app.ports.notify.subscribe(
    app.ports.notifications.send
  );

  const sendTimestamp = function() {
    app.ports.timestamps.send(now());
  };

  const schedule = function() {
    setTimeout(() => {
      schedule();
      sendTimestamp();
    }, (60 - seconds()) * 1000);
  };

  schedule();
};
