/**
 * @typedef {import('bcp-47').Schema} Schema
 * @typedef {import('type-fest').PackageJson} PackageJson
 */

/**
 * @typedef Info
 * @property {string} code
 *   BCP 47 tag.
 * @property {boolean} hasLicense
 *   Whether a license file exists.
 * @property {string} langName
 *   Language name.
 * @property {string} source
 *   Source URL.
 * @property {string} variable
 *   Variable name.
 */

import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import {parse} from 'bcp-47'
import {iso15924} from 'iso-15924'
import {iso31661} from 'iso-3166'
import {iso6393} from 'iso-639-3'

/** @type {PackageJson} */
const pkg = JSON.parse(String(await fs.readFile('package.json')))

const docs = String(
  await fs.readFile(new URL('template/readme.md', import.meta.url))
)
const main = String(
  await fs.readFile(new URL('template/index.js', import.meta.url))
)
const root = new URL('../dictionaries/', import.meta.url)
const files = await fs.readdir(root)
const dictionaries = files
  .filter(function (d) {
    return d.charAt(0) !== '.'
  })
  .sort()
let index = -1

while (++index < dictionaries.length) {
  const code = dictionaries[index]
  const base = new URL(code + '/', root)
  const tag = parse(code)
  /** @type {Array<string>} */
  const parts = []
  /** @type {PackageJson} */
  let pack = {}
  const keywords = ['spelling', 'myspell', 'hunspell', 'dictionary']
  /** @type {string} */
  let source
  /** @type {string} */
  let langName

  try {
    source = String(await fs.readFile(new URL('.source', base))).trim()
  } catch {
    console.log('Cannot find dictionary for `%s`', code)
    continue
  }

  try {
    pack = JSON.parse(String(await fs.readFile(new URL('package.json', base))))
  } catch {}

  keywords.push(...code.toLowerCase().split('-'))
  /** @type {keyof Schema} */
  let key

  for (key in tag) {
    if (!Object.hasOwn(tag, key)) continue

    const value = /** @type {Array<string>} */ (
      Array.isArray(tag[key]) ? tag[key] : [tag[key]]
    )
    let offset = -1

    while (++offset < value.length) {
      const subvalue = value[offset]
      if (!subvalue) continue
      /** @type {string | undefined} */
      let displayName

      if (key === 'language') {
        const value = iso6393.find(function (d) {
          return d.iso6391 === subvalue || d.iso6393 === subvalue
        })
        assert(value, 'expected ISO 639-1 or 639-3 language `' + subvalue + '`')
        displayName = value.name
          .replace(/\([^)]+\)/, '')
          .replace(/modern/i, '')
          .trim()
        parts.push(displayName)
      } else if (key === 'script') {
        const value = iso15924.find(function (d) {
          return d.code === subvalue
        })
        assert(value, 'expected ISO 15924 script `' + subvalue + '`')
        displayName = value.name
        parts.push(displayName + ' script')
      } else if (key === 'region') {
        const value = iso31661.find(function (d) {
          return d.alpha2 === subvalue
        })
        assert(value, 'expected ISO 3166-1 region `' + subvalue + '`')
        displayName = value.name
          .replace(/of Great Britain .*/, '')
          .replace(/\([^)]+\)/, '')
          .trim()
        parts.push(displayName)
      } else if (key === 'variants') {
        assert(
          subvalue === 'valencia' || subvalue === 'polyton',
          'expected only supported variant valencia'
        )
        displayName = subvalue.charAt(0).toUpperCase() + subvalue.slice(1)
        parts.push(displayName)
      }

      assert(displayName, 'expected `displayName`')
      keywords.push(...displayName.toLowerCase().split(' '))
    }
  }

  langName = parts[0]

  if (parts.length > 1) {
    langName += ' (' + parts.slice(1).join('; ') + ')'
  }

  assert(pkg.bugs, 'expected `bugs`')
  assert(pkg.funding, 'expected `funding`')
  assert(pkg.author, 'expected `author`')
  assert(pkg.contributors, 'expected `contributors`')
  pack = {
    name: 'dictionary-' + code.toLowerCase(),
    version: pack.version || '0.0.0',
    description: langName + ' spelling dictionary',
    license: String(await fs.readFile(new URL('.spdx', base))).trim(),
    keywords: [...new Set(keywords)].sort(),
    repository: pkg.repository + '/tree/main/dictionaries/' + code,
    bugs: pkg.bugs,
    funding: pkg.funding,
    author: pkg.author,
    contributors: pkg.contributors,
    type: 'module',
    files: ['index.aff', 'index.d.ts', 'index.dic', 'index.js', 'index.map']
  }

  let exists = false

  try {
    await fs.access(new URL('license', base), fs.constants.F_OK)
    exists = true
  } catch {}

  await fs.writeFile(
    new URL('readme.md', base),
    process(docs, pack, {
      code,
      hasLicense: exists,
      langName,
      source,
      variable: camelcase(code.toLowerCase())
    })
  )

  await fs.writeFile(new URL('index.js', base), main)

  await fs.writeFile(
    new URL('package.json', base),
    JSON.stringify(pack, undefined, 2) + '\n'
  )
}

/**
 * Generate a readme.
 *
 * @param {string} file
 *   Template.
 * @param {PackageJson} pkg
 *   Package.
 * @param {Info} info
 *   Info.
 * @returns {string}
 *   Result.
 */
function process(file, pkg, info) {
  assert(pkg.name, 'expected description')
  assert(pkg.description, 'expected description')
  assert(pkg.license, 'expected license')
  let license = pkg.license
  const source = info.source
  const uri = new URL(source)
  let sourceName = uri.host

  // Clean name.
  if (sourceName === 'github.com') {
    sourceName = uri.pathname.slice(1)
  } else if (sourceName === 'gitlab.com') {
    sourceName = 'gl:' + uri.pathname.slice(1)
  } else if (sourceName === 'sites.google.com') {
    sourceName = uri.pathname.split('/')[2]
  } else if (sourceName.slice(0, 4) === 'www.') {
    sourceName = sourceName.slice(4)
  }

  if (info.hasLicense) {
    license =
      '[' +
      license +
      '](https://github.com/wooorm/' +
      'dictionaries/blob/main/dictionaries/' +
      info.code +
      '/license)'
  }

  return file
    .replace(/{{NAME}}/g, pkg.name)
    .replace(/{{LANG}}/g, info.langName)
    .replace(/{{DESCRIPTION}}/g, pkg.description)
    .replace(/{{SPDX}}/g, pkg.license)
    .replace(/{{SOURCE}}/g, source)
    .replace(/{{SOURCE_NAME}}/g, sourceName)
    .replace(/{{VAR}}/g, info.variable)
    .replace(
      /{{VAR_CAP}}/g,
      info.variable.charAt(0).toUpperCase() + info.variable.slice(1)
    )
    .replace(/{{CODE}}/g, info.code)
    .replace(/{{LICENSE}}/g, license)
}

/**
 * @param {string} value
 *   Value.
 * @returns {string}
 *   Result.
 */
function camelcase(value) {
  return value.replace(/-[a-z]/gi, replace)

  /**
   * @param {string} d
   *   Value.
   * @returns {string}
   *   Result.
   */
  function replace(d) {
    return d.charAt(1).toUpperCase()
  }
}
