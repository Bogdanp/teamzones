var format = function(format) {
  return function(timestamp) {
    return moment(timestamp).format(format);
  };
};

var formatWithTimezone = function(timezone) {
  return function(format) {
    return function(timestamp) {
      return moment(timestamp).tz(timezone).format(format);
    };
  };
};

var offset = function(timezone) {
  return moment.tz(timezone).utcOffset();
};

var make = function make(elm) {
  elm.Native = elm.Native || {};
  elm.Native.Timestamp = elm.Native.Timestamp || {};

  if (elm.Native.Timestamp.values) {
    return elm.Native.Timestamp.values;
  }

  return elm.Native.Timestamp.values = {
    format: format,
    formatWithTimezone: formatWithTimezone,
    offset: offset
  };
};

Elm.Native.Timestamp = {};
Elm.Native.Timestamp.make = make;
