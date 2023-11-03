/**
 * @typedef Dictionary
 *   Hunspell dictionary.
 * @property {Uint8Array} aff
 *   Data for the affix file (defines the language, keyboard, flags, and more).
 * @property {Uint8Array} dic
 *   Data for the dictionary file (contains words and flags applying to those words).
 */

import fs from 'node:fs/promises'

const aff = await fs.readFile(new URL('index.aff', import.meta.url))
const dic = await fs.readFile(new URL('index.dic', import.meta.url))

/** @type {Dictionary} */
const dictionary = {aff, dic}

export default dictionary
