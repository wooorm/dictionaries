const {readFile: read} = require('fs')
const {join} = require('path')

/**
 * Loads the affix file and dictionary file and returns them in a
 * callback if successfully loaded. The callback provides an error
 * if it was unable to load either of the files.
 *
 * @param {(err?: Error, doc?: { aff: Buffer, dic: Buffer }) => void} callback
 */
function load(callback) {
  let pos = -1
  let exception = null
  let result = {}

  one('aff')
  one('dic')

  function one(name) {
    read(join(__dirname, 'index.' + name), function(err, doc) {
      pos++
      exception = exception || err
      result[name] = doc

      if (pos) {
        callback(exception, exception ? null : result)
        exception = null
        result = null
      }
    })
  }
}
module.exports = load
