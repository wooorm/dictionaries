'use strict'

var fs = require('fs')
var path = require('path')
var xtend = require('xtend')
var hidden = require('is-hidden')
var negate = require('negate')
var bcp47 = require('bcp-47')
var tags = require('language-tags')
var pkg = require('../package.json')

var dir = fs.readdirSync
var exists = fs.existsSync
var read = fs.readFileSync
var write = fs.writeFileSync
var join = path.join

var docs = read(template('readme.md'), 'utf-8')
var index = read(template('index.js'), 'utf-8')

var types = {
  variants: 'variant',
  extensions: 'extlang'
}

var remove = {
  ca: ['or Valencian', 'Valencian'],
  'ca-valencia': ['or Valencian'],
  el: ['(1453-)'],
  'el-polyton': ['(1453-)'],
  ia: ['International Auxiliary Language Association'],
  ne: ['(macrolanguage)']
}

var replace = {
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
    var base = dict(code)
    var tag = bcp47.parse(code)
    var parts = []
    var pack = {}
    var keywords = ['spelling', 'myspell', 'hunspell', 'dictionary']
    var source
    var description

    try {
      source = read(join(base, 'SOURCE'), 'utf-8').trim()
    } catch (error) {
      console.log('Cannot find dictionary for `%s`', code)
      return
    }

    try {
      pack = JSON.parse(read(join(base, 'package.json')))
    } catch (error) {}

    keywords = keywords.concat(code.toLowerCase().split('-'))

    Object.keys(tag).forEach(function(key) {
      var label = types[key] || key
      var value = tag[key]

      value = value && typeof value === 'object' ? value : [value]

      value.forEach(function(subvalue) {
        var subtag = subvalue ? tags.type(subvalue, label) : null
        var data = subtag ? subtag.data.record.Description : null

        if (data) {
          /* Fix bug in `language-tags`, where the description of a tag when
           * indented is seen as an array, instead of continued text. */
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
      license: read(join(base, 'SPDX'), 'utf-8').trim(),
      keywords: keywords,
      repository: pkg.repository + '/tree/master/dictionaries/' + code,
      bugs: pkg.bugs,
      author: pkg.author,
      contributors: pkg.contributors,
      files: ['index.js', 'index.aff', 'index.dic']
    }

    write(
      join(base, 'readme.md'),
      process(
        docs,
        xtend(pack, {
          source: source,
          variable: camelcase(code),
          code: code,
          hasLicense: exists(join(base, 'LICENSE'))
        })
      )
    )

    write(join(base, 'index.js'), index)

    write(join(base, 'package.json'), JSON.stringify(pack, 0, 2) + '\n')

    function ignore(val) {
      return remove[code] ? remove[code].indexOf(val) === -1 : true
    }

    function change(val) {
      return (replace[code] ? replace[code][val] : null) || val
    }
  })

function process(file, config) {
  var license = config.license
  var source = config.source
  var uri = new URL(source)
  var sourceName = uri.host

  /* Clean name */
  if (sourceName === 'github.com') {
    sourceName = uri.pathname.slice(1)
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
      'dictionaries/blob/master/dictionaries/' +
      config.code +
      '/LICENSE)'
  }

  return file
    .replace(/\{\{NAME\}\}/g, config.name)
    .replace(/\{\{DESCRIPTION\}\}/g, config.description)
    .replace(/\{\{SPDX\}\}/g, config.license)
    .replace(/\{\{SOURCE\}\}/g, source)
    .replace(/\{\{SOURCE_NAME\}\}/g, sourceName)
    .replace(/\{\{VAR\}\}/g, config.variable)
    .replace(/\{\{CODE\}\}/g, config.code)
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
