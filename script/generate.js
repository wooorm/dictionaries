import fs from 'node:fs'
import path from 'node:path'
import {isHidden} from 'is-hidden'
import {parse} from 'bcp-47'
import tags from 'language-tags'

const own = {}.hasOwnProperty

const pkg = JSON.parse(String(fs.readFileSync('package.json')))

const docs = String(
  fs.readFileSync(path.join('script', 'template', 'readme.md'))
)
const main = String(
  fs.readFileSync(path.join('script', 'template', 'index.js'))
)
const types = String(
  fs.readFileSync(path.join('script', 'template', 'index.d.ts'))
)

const labels = {
  variants: 'variant',
  extensions: 'extlang'
}

const remove = {
  ca: ['or Valencian', 'Valencian'],
  'ca-valencia': ['or Valencian'],
  el: ['(1453-)'],
  'el-polyton': ['(1453-)'],
  ia: ['International Auxiliary Language Association'],
  ne: ['(macrolanguage)']
}

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

const dictionaries = fs
  .readdirSync('dictionaries')
  .filter((d) => !isHidden(d))
  .sort()
let index = -1

while (++index < dictionaries.length) {
  const code = dictionaries[index]
  const base = path.join('dictionaries', code)
  const tag = parse(code)
  let parts = []
  let pack = {}
  let keywords = ['spelling', 'myspell', 'hunspell', 'dictionary']
  let source
  let langName

  try {
    source = fs.readFileSync(path.join(base, '.source'), 'utf8').trim()
  } catch {
    console.log('Cannot find dictionary for `%s`', code)
    continue
  }

  try {
    pack = JSON.parse(fs.readFileSync(path.join(base, 'package.json')))
  } catch {}

  keywords = keywords.concat(code.toLowerCase().split('-'))
  let key

  for (key in tag) {
    if (!own.call(tag, key)) continue

    const label = labels[key] || key
    const value = Array.isArray(tag[key]) ? tag[key] : [tag[key]]
    let offset = -1

    while (++offset < value.length) {
      const subvalue = value[offset]
      if (!subvalue) continue
      const subtag = subvalue ? tags.type(subvalue, label) : null
      let data = subtag ? subtag.data.record.Description : null

      // Fix bug in `language-tags`, where the description of a tag when
      // indented is seen as an array, instead of continued text.
      if (subtag.data.subtag === 'ia') {
        data = [data.join(' ')]
      }

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

  pack = {
    name: 'dictionary-' + code.toLowerCase(),
    version: pack.version || '0.0.0',
    description: langName + ' spelling dictionary',
    license: fs.readFileSync(path.join(base, '.spdx'), 'utf8').trim(),
    keywords,
    repository: pkg.repository + '/tree/main/dictionaries/' + code,
    bugs: pkg.bugs,
    funding: pkg.funding,
    author: pkg.author,
    contributors: pkg.contributors,
    files: ['index.js', 'index.aff', 'index.dic', 'index.d.ts']
  }

  fs.writeFileSync(
    path.join(base, 'readme.md'),
    process(
      docs,
      Object.assign({}, pack, {
        langName,
        source,
        variable: camelcase(code.toLowerCase()),
        code,
        hasLicense: fs.existsSync(path.join(base, 'license'))
      })
    )
  )

  fs.writeFileSync(path.join(base, 'index.js'), main)

  fs.writeFileSync(path.join(base, 'index.d.ts'), types)

  fs.writeFileSync(
    path.join(base, 'package.json'),
    JSON.stringify(pack, null, 2) + '\n'
  )
}

function process(file, config) {
  let license = config.license
  const source = config.source
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

  if (config.hasLicense) {
    license =
      '[' +
      license +
      '](https://github.com/wooorm/' +
      'dictionaries/blob/main/dictionaries/' +
      config.code +
      '/license)'
  }

  return file
    .replace(/{{NAME}}/g, config.name)
    .replace(/{{LANG}}/g, config.langName)
    .replace(/{{DESCRIPTION}}/g, config.description)
    .replace(/{{SPDX}}/g, config.license)
    .replace(/{{SOURCE}}/g, source)
    .replace(/{{SOURCE_NAME}}/g, sourceName)
    .replace(/{{VAR}}/g, config.variable)
    .replace(
      /{{VAR_CAP}}/g,
      config.variable.charAt(0).toUpperCase() + config.variable.slice(1)
    )
    .replace(/{{CODE}}/g, config.code)
    .replace(/{{LICENSE}}/g, license)
}

function camelcase(value) {
  return value.replace(/-[a-z]/gi, replace)
  function replace(d) {
    return d.charAt(1).toUpperCase()
  }
}
