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
import tags from 'language-tags'

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

/** @type {Partial<Record<keyof Schema, string>>} */
const labels = {
  variants: 'variant',
  extensions: 'extlang'
}

/** @type {Record<string, Array<string>>} */
const remove = {
  ca: ['or Valencian', 'Valencian'],
  'ca-valencia': ['or Valencian'],
  el: ['(1453-)'],
  'el-polyton': ['(1453-)'],
  ia: ['International Auxiliary Language Association'],
  ne: ['(macrolanguage)']
}

/** @type {Record<string, Record<string, string>>} */
const replace = {
  el: {'Modern Greek (1453-)': 'Modern Greek'},
  'el-polyton': {'Modern Greek (1453-)': 'Modern Greek'},
  ia: {
    '(international': 'international',
    'association)': 'association',
    'Interlingua (International Auxiliary Language Association)': 'Interlingua'
  },
  ne: {'Nepali (macrolanguage)': 'Nepali'},
  oc: {'(post': 'post', '1500)': '1500'}
}

const root = new URL('../dictionaries/', import.meta.url)
const files = await fs.readdir(root)
const dictionaries = files.filter((d) => !isHidden(d)).sort()
let index = -1

while (++index < dictionaries.length) {
  const code = dictionaries[index]
  const base = new URL(code + '/', root)
  const tag = parse(code)
  /** @type {Array<string>} */
  let parts = []
  /** @type {PackageJson} */
  let pack = {}
  let keywords = ['spelling', 'myspell', 'hunspell', 'dictionary']
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

  keywords = [...keywords, ...code.toLowerCase().split('-')].sort()
  /** @type {keyof Schema} */
  let key

  for (key in tag) {
    if (!own.call(tag, key)) continue

    const label = labels[key] || key
    const value = /** @type {Array<string>} */ (
      Array.isArray(tag[key]) ? tag[key] : [tag[key]]
    )
    let offset = -1

    while (++offset < value.length) {
      const subvalue = value[offset]
      if (!subvalue) continue
      const subtag = subvalue ? tags.type(subvalue, label) : null
      /** @type {Array<string>|null} */
      // @ts-expect-error: exists.
      let data = subtag ? subtag.data.record.Description : null

      // Fix bug in `language-tags`, where the description of a tag when
      // indented is seen as an array, instead of continued text.
      // @ts-expect-error: exists.
      if (subtag.data.subtag === 'ia' && data) {
        data = [data.join(' ')]
      }

      assert(data, 'expected subtag')
      keywords = keywords.concat(data.join(' ').toLowerCase().split(' '))

      if (label === 'language') {
        parts = [data[0]].concat(
          data.slice(1).map((x) => 'or ' + x),
          parts
        )
      } else if (label === 'script') {
        parts = parts.concat(data.join(' ') + ' script')
      } else {
        parts = parts.concat(data)
      }
    }
  }

  keywords = keywords
    .filter(Boolean)
    .filter((key, index, parent) => !parent.includes(key, index + 1))
    .filter((d) => (remove[code] ? !remove[code].includes(d) : true))
    .map((d) => (replace[code] ? replace[code][d] : null) || d)

  parts = parts
    .filter(Boolean)
    .filter((key, index, parent) => !parent.includes(key, index + 1))
    .filter((d) => (remove[code] ? !remove[code].includes(d) : true))
    .map((d) => (replace[code] ? replace[code][d] : null) || d)

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
    keywords,
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
