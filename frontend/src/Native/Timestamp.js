var format = function(format, timestamp) {
  return moment(timestamp).format(format);
};

var formatWithTimezone = function(timezone, format, timestamp) {
  return moment(timestamp).tz(timezone).format(format);
};

var offset = function(timezone) {
  return moment.tz(timezone).utcOffset();
};

var _Bogdanp$teamzones$Native_Timestamp = function() {
  return {
    format: F2(format),
    formatWithTimezone: F3(formatWithTimezone),
    offset: offset
  };
}();
