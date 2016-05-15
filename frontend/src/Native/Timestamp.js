var format = function(format, timestamp) {
  return moment(timestamp).format(format);
};

var formatWithTimezone = function(timezone, format, timestamp) {
  return moment(timestamp).tz(timezone).format(format);
};

var offset = function(timezone) {
  return moment.tz(timezone).utcOffset();
};

var currentHour = function(timezone)  {
  var hour = moment.tz(timezone).hour();

  return (hour === 0) ? 24 : hour;
};

var currentDay = function(timezone)  {
  return moment.tz(timezone).isoWeekday();
};

var _Bogdanp$teamzones$Native_Timestamp = function() {
  return {
    format: F2(format),
    formatWithTimezone: F3(formatWithTimezone),
    offset: offset,
    currentDay: currentDay,
    currentHour: currentHour
  };
}();
