/**
 * @typedef {import('type-fest').PackageJson} PackageJson
 * @typedef {import('bcp-47').Schema} Schema
 *
 * @typedef Info
 * @property {string} langName
 * @property {string} source
 * @property {string} variable
 * @property {string} code
 * @property {boolean} hasLicense
 */

import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import {isHidden} from 'is-hidden'
import {parse} from 'bcp-47'
import {iso15924} from 'iso-15924'
import {iso31661} from 'iso-3166'
import {iso6393} from 'iso-639-3'

/* eslint-disable no-await-in-loop */

const own = {}.hasOwnProperty

/** @type {PackageJson} */
const pkg = JSON.parse(String(await fs.readFile('package.json')))

const docs = String(
  await fs.readFile(new URL('template/readme.md', import.meta.url))
)
const main = String(
  await fs.readFile(new URL('template/index.js', import.meta.url))
)
const types = String(
  await fs.readFile(new URL('template/index.d.ts', import.meta.url))
)

const root = new URL('../dictionaries/', import.meta.url)
const files = await fs.readdir(root)
const dictionaries = files.filter((d) => !isHidden(d)).sort()
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
    if (!own.call(tag, key)) continue

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
        const value = iso6393.find(
          (d) => d.iso6391 === subvalue || d.iso6393 === subvalue
        )
        assert(value, 'expected ISO 639-1 or 639-3 language `' + subvalue + '`')
        displayName = value.name
          .replace(/\([^)]+\)/, '')
          .replace(/modern/i, '')
          .trim()
        parts.push(displayName)
      } else if (key === 'script') {
        const value = iso15924.find((d) => d.code === subvalue)
        assert(value, 'expected ISO 15924 script `' + subvalue + '`')
        displayName = value.name
        parts.push(displayName + ' script')
      } else if (key === 'region') {
        const value = iso31661.find((d) => d.alpha2 === subvalue)
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
    files: ['index.aff', 'index.d.ts', 'index.dic', 'index.js']
  }

  let exists = false

  try {
    await fs.access(new URL('license', base), fs.constants.F_OK)
    exists = true
  } catch {}

  await fs.writeFile(
    new URL('readme.md', base),
    process(docs, pack, {
      langName,
      source,
      variable: camelcase(code.toLowerCase()),
      code,
      hasLicense: exists
    })
  )

  await fs.writeFile(new URL('index.js', base), main)

  await fs.writeFile(new URL('index.d.ts', base), types)

  await fs.writeFile(
    new URL('package.json', base),
    JSON.stringify(pack, null, 2) + '\n'
  )
}

/**
 *
 * @param {string} file
 * @param {PackageJson} pkg
 * @param {Info} info
 * @returns {string}
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
 *
 * @param {string} value
 * @returns {string}
 */

function camelcase(value) {
  return value.replace(/-[a-z]/gi, replace)
  function replace(d) {
    return d.charAt(1).toUpperCase()
  }
}

/* eslint-enable no-await-in-loop */
