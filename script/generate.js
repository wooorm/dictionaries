'use strict'

const {
  readdirSync: dir,
  existsSync: exists,
  readFileSync: read,
  writeFileSync: write,
} = require('fs')
const { join } = require('path')
const xtend = require('xtend')
const hidden = require('is-hidden')
const negate = require('negate')
const bcp47 = require('bcp-47')
const tags = require('language-tags')
const pkg = require('../package.json')

const docs = read(template('readme.md'), 'utf-8')
const index = read(template('index.js'), 'utf-8')
const typings = read(template('index.d.ts'), 'utf-8')

const types = {
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
  ne: {'Nepali (macrolanguage)': 'Nepali'}
}

dir('dictionaries')
  .filter(negate(hidden))
  .sort()
  .forEach(function(code) {
    const base = dict(code)
    const tag = bcp47.parse(code)
    let parts = []
    let pack = {}
    let keywords = ['spelling', 'myspell', 'hunspell', 'dictionary']
    let source
    let description

    try {
      source = read(join(base, '.source'), 'utf-8').trim()
    } catch (error) {
      console.log('Cannot find dictionary for `%s`', code)
      return
    }

    try {
      pack = JSON.parse(read(join(base, 'package.json')))
    } catch (error) {}

    keywords = keywords.concat(code.toLowerCase().split('-'))

    Object.keys(tag).forEach(function(key) {
      const label = types[key] || key
      let value = tag[key]

      value = value && typeof value === 'object' ? value : [value]

      value.forEach(function(subvalue) {
        const subtag = subvalue ? tags.type(subvalue, label) : null
        let data = subtag ? subtag.data.record.Description : null

        if (data) {
          // Fix bug in `language-tags`, where the description of a tag when
          // indented is seen as an array, instead of continued text.
          if (subtag.data.subtag === 'ia') {
            data = [data.join(' ')]
          }

          keywords = keywords.concat(
            data
              .join(' ')
              .toLowerCase()
              .split(' ')
          )

          if (label === 'language') {
            parts = [data[0]].concat(
              data.slice(1).map(function(x) {
                return 'or ' + x
              }),
              parts
            )
          } else {
            parts = parts.concat(data)
          }
        }
      })
    })

    keywords = keywords
      .filter(Boolean)
      .filter(unique)
      .filter(ignore)
      .map(change)
    parts = parts
      .filter(Boolean)
      .filter(unique)
      .filter(ignore)
      .map(change)

    description = parts[0]

    if (parts.length > 1) {
      description += ' (' + parts.slice(1).join(', ') + ')'
    }

    pack = {
      name: 'dictionary-' + code.toLowerCase(),
      version: pack.version || '0.0.0',
      description: description + ' spelling dictionary in UTF-8',
      license: read(join(base, '.spdx'), 'utf-8').trim(),
      keywords: keywords,
      repository: pkg.repository + '/tree/master/dictionaries/' + code,
      bugs: pkg.bugs,
      author: pkg.author,
      contributors: pkg.contributors,
      files: ['index.js', 'index.aff', 'index.dic', 'index.d.ts'],
      types: 'index.d.ts'
    }

    write(
      join(base, 'readme.md'),
      process(
        docs,
        xtend(pack, {
          source: source,
          variable: camelcase(code),
          code: code,
          hasLicense: exists(join(base, 'license'))
        })
      )
    )

    write(join(base, 'index.js'), index)

    write(join(base, 'index.d.ts'), typings)

    write(join(base, 'package.json'), JSON.stringify(pack, 0, 2) + '\n')
    
    function ignore(val) {
      return remove[code] ? remove[code].indexOf(val) === -1 : true
    }

    function change(val) {
      return (replace[code] ? replace[code][val] : null) || val
    }
  })

function process(file, config) {
  let { 
    license, 
    source,
    name,
    description,
    variable,
    code,
    hasLicense
  } = config
  const uri = new URL(source)
  let sourceName = uri.host

  // Clean name.
  if (sourceName === 'github.com') {
    sourceName = uri.pathname.slice(1)
  } else if (sourceName === 'sites.google.com') {
    sourceName = uri.pathname.split('/')[2]
  } else if (sourceName.slice(0, 4) === 'www.') {
    sourceName = sourceName.slice(4)
  }

  if (hasLicense) {
    license =
      '[' +
      license +
      '](https://github.com/wooorm/' +
      'dictionaries/blob/master/dictionaries/' +
      code +
      '/license)'
  }

  return file
    .replace(/\{\{NAME\}\}/g, name)
    .replace(/\{\{DESCRIPTION\}\}/g, description)
    .replace(/\{\{SPDX\}\}/g, license)
    .replace(/\{\{SOURCE\}\}/g, source)
    .replace(/\{\{SOURCE_NAME\}\}/g, sourceName)
    .replace(/\{\{VAR\}\}/g, variable)
    .replace(/\{\{CODE\}\}/g, code)
    .replace(/\{\{LICENSE\}\}/g, license)
}

function template(fileName) {
  return join(__dirname, 'template', fileName)
}

function dict(code) {
  return join('dictionaries', code)
}

function unique(key, index, parent) {
  return parent.indexOf(key, index + 1) === -1
}

function camelcase(value) {
  return value.replace(/-[a-z]/gi, replace)
  function replace(d) {
    return d.charAt(1).toUpperCase()
  }
}
