var format = function(format, timestamp) {
  return moment(timestamp).format(format);
};

var formatWithTimezone = function(timezone, format, timestamp) {
  return moment(timestamp).tz(timezone).format(format);
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
    format: F2(format),
    formatWithTimezone: F3(formatWithTimezone),
    offset: offset
  };
};

Elm.Native.Timestamp = {};
Elm.Native.Timestamp.make = make;
