/* Dependencies. */
var read = require('fs').readFile;
var join = require('path').join;

/* Expose. */
module.exports = load;

/* Load the dictionary-en-gb dictionaries. */
function load(callback) {
  var pos = -1;
  var exception = null;
  var result = {};

  one('aff');
  one('dic');

  function one(name) {
    read(join(__dirname, 'index.' + name), function (err, doc) {
      pos++;
      exception = exception || err;
      result[name] = doc;

      if (pos) {
        callback(exception, exception ? null : result);
        result = exception = null;
      }
    });
  }
}
