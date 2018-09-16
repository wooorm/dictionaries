'use strict'

var fs = require('fs')
var path = require('path')
var assert = require('assert')
var test = require('tape')
var vfile = require('to-vfile')
var bail = require('bail')
var not = require('not')
var hidden = require('is-hidden')
var isUTF8 = require('utf-8-validate')

var root = 'dictionaries'

var checks = {
  'All required files should exist': requiredFiles,
  'All files should be in UTF-8': utf8
}

function utf8(name) {
  var dirname = path.join(root, name)

  fs.readdirSync(dirname)
    .filter(not(hidden))
    .forEach(check)

  function check(filename) {
    var file = vfile.readSync(path.join(dirname, filename))
    assert.ok(isUTF8(file.contents), file.basename + ' should be utf8')
  }
}

function requiredFiles(name) {
  var dirname = path.join(root, name)
  var files = fs.readdirSync(dirname).filter(not(hidden))
  var paths = [
    'index.dic',
    'index.aff',
    'readme.md',
    'index.js',
    'package.json'
  ]

  paths.forEach(check)

  function check(basename) {
    assert.notStrictEqual(
      files.indexOf(basename),
      -1,
      'should have `' + basename + '`'
    )
  }
}

test('dictionaries', function(t) {
  fs.readdir(root, ondir)

  function ondir(err, paths) {
    bail(err)

    paths = paths.filter(not(hidden))

    t.plan(paths.length)

    paths.forEach(check, t)
  }
})

function check(basename) {
  this.test(basename, all)

  function all(st) {
    var descriptions = Object.keys(checks)

    st.plan(descriptions.length)

    descriptions.forEach(one)

    function one(description) {
      st.doesNotThrow(check, description)

      function check() {
        checks[description](basename)
      }
    }
  }
}
