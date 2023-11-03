/**
 * @callback Callback
 *   Callback.
 * @param {Error | undefined} error
 *   Error.
 * @param {Dictionary | undefined} [dictionary]
 *   Dictionary.
 *
 * @typedef Dictionary
 *   Hunspell dictionary.
 * @property {Uint8Array} aff
 *   Data for the affix file (defines the language, keyboard, flags, and more).
 * @property {Uint8Array} dic
 *   Data for the dictionary file (contains words and flags applying to those words).
 */

const fs = require('fs')
const path = require('path')

module.exports = load

/**
 * @param {Callback} callback
 *   Callback.
 * @returns {undefined}
 *   Nothing.
 */
function load(callback) {
  /** @type {Dictionary} */
  // @ts-expect-error: filled later.
  let result = {}
  let pos = -1
  /** @type {Error | undefined} */
  let exception

  one('aff')
  one('dic')

  /**
   * @param {'aff' | 'dic'} name
   *   Name.
   * @returns {undefined}
   *   Nothing.
   */
  function one(name) {
    fs.readFile(path.join(__dirname, 'index.' + name), function (error, doc) {
      pos++
      exception = exception || error || undefined
      result[name] = doc

      if (pos) {
        if (exception) {
          callback(exception)
        } else {
          callback(undefined, result)
        }

        exception = undefined
        // @ts-expect-error: free memory.
        result = undefined
      }
    })
  }
}
