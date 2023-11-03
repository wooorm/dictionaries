/**
 * @callback Callback
 * @param {NodeJS.ErrnoException | undefined} error
 * @param {Dictionary | undefined} [dictionary]
 *
 * @typedef Dictionary
 *   Hunspell dictionary.
 * @property {Buffer} aff
 *   Buffer in UTF-8 for the affix file (defines the language, keyboard, flags, and more).
 * @property {Buffer} dic
 *   Buffer in UTF-8 for the dictionary file (contains words and flags applying to those words).
 */

const fs = require('fs')
const path = require('path')

module.exports = load

/**
 * @param {Callback} callback
 * @returns {undefined}
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
   */
  function one(name) {
    fs.readFile(path.join(__dirname, 'index.' + name), (error, doc) => {
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
