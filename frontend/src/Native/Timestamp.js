var format = function(format, timestamp) {
  return moment(timestamp).format(format);
};

var formatWithTimezone = function(timezone, format, timestamp) {
  return moment(timestamp).tz(timezone).format(format);
};

var offset = function(timezone) {
  return moment.tz(timezone).utcOffset();
};

var currentHour = function(timezone, timestamp)  {
  var hour = moment(timestamp).tz(timezone).hour();

  return (hour === 0) ? 24 : hour;
};

var currentDay = function(timezone, timestamp)  {
  return moment(timestamp).tz(timezone).isoWeekday();
};

var fromString = function(string) {
  return moment(string).toDate().getTime();
};

var isoFormat = function(timestamp) {
  return moment(timestamp).toISOString();
};

var _Bogdanp$teamzones$Native_Timestamp = function() {
  return {
    format: F2(format),
    formatWithTimezone: F3(formatWithTimezone),
    offset: offset,
    currentDay: F2(currentDay),
    currentHour: F2(currentHour),
    fromString: fromString,
    isoFormat: isoFormat
  };
}();
