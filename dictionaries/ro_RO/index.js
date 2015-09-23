/**
 * @author Titus Wormer
 * @copyright 2015 Titus Wormer
 * @license MIT
 * @module dictionary-ro
 * @fileoverview Romanian (Romania) spelling dictionary in UTF-8.
 */

/*
 * Dependencies.
 */

var read = require('fs').readFile;
var join = require('path').join;

/**
 * A dictionary.
 *
 * @typedef {Object} Dictionary
 * @property {Buffer} dic - Dictionary buffer in UTF-8.
 * @property {Buffer} add - Affix buffer in UTF-8.
 */

/**
 * Callback invoked with a dictionary.
 *
 * @callback callback
 * @param {Error?} err - Error while reading the dictionary
 *   files.
 * @param {Dictionary?} dictionary - A dictionary.
 */

/**
 * Load the dictionaries.
 *
 * @param {callback} callback
 */
function load(callback) {
    var pos = -1;
    var exception = null;
    var result = {};

    /**
     * Load a file.
     *
     * @param {string} name - Extension and type of file
     *   to load.
     */
    function one(name) {
        read(join(__dirname, 'index.' + name), function (err, doc) {
            pos++;

            if (exception) {
                return;
            }

            if (err) {
                exception = err;
                callback(err);

                return;
            }

            result[name] = doc;

            if (pos) {
                callback(exception, !exception && result)
            }
        });
    }

    one('aff');
    one('dic');
}

/*
 * Expose.
 */

module.exports = load;
