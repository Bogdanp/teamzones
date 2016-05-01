var format = function(timestamp) {
  return function(format) {
    return moment(timestamp).format(format);
  };
};

var formatWithTimezone = function(timezone) {
  return function(timestamp) {
    return function(format) {
      return moment(timestamp).tz(timezone).format(format);
    };
  };
};

var make = function make(elm) {
    elm.Native = elm.Native || {};
    elm.Native.Timestamp = elm.Native.Timestamp || {};

    if (elm.Native.Timestamp.values) return elm.Native.Timestamp.values;

    return elm.Native.Timestamp.values = {
      'format': format,
      'formatWithTimezone': formatWithTimezone
    };
};

Elm.Native.Timestamp = {};
Elm.Native.Timestamp.make = make;
