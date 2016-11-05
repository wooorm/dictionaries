'use strict';

/* eslint-disable max-params */

/* Dependencies. */
var fs = require('fs');
var path = require('path');
var hidden = require('is-hidden');
var negate = require('negate');
var iso6391 = require('langs');
var iso6392 = require('iso-639-2');
var iso3166 = require('iso-3166-1-alpha-2');
var iso15924 = require('iso-15924');

/* Methods. */
var dir = fs.readdirSync;
var exists = fs.existsSync;
var read = fs.readFileSync;
var write = fs.writeFileSync;
var join = path.join;

/* Constants. */
var docs = read(template('readme.md'), 'utf-8');
var index = read(template('index.js'), 'utf-8');

/* Generate. */
dir('dictionaries').filter(negate(hidden)).sort().forEach(function (code) {
  var base = dict(code);
  var template = {};
  var source = read(join(base, 'SOURCE'), 'utf-8').trim();
  var hasLicense = exists(join(base, 'LICENSE'));
  var spdx = read(join(base, 'SPDX'), 'utf-8').trim();
  var segments = code.toLowerCase().replace(/[^a-z]+/g, '-').split('-');
  var lang = iso6391.where('1', segments[0]) || find(iso6392, segments[0]);
  var region = iso3166.getCountry(segments[1].toUpperCase());
  var rest = segments[2];
  var script;
  var variable;
  var readme;
  var pack;
  var name;
  var keywords;
  var description;
  var flag;
  var pos;
  var length;

  if (rest) {
    pos = -1;
    length = iso15924.length;

    while (++pos < length) {
      if (iso15924[pos].code.toLowerCase() === rest.toLowerCase()) {
        script = iso15924[pos];
        break;
      }
    }
  }

  if (exists(join(base, 'package.json'))) {
    pack = JSON.parse(read(join(base, 'package.json')));
  } else {
    pack = {};
  }

  lang = lang ? lang.name : null;
  rest = script ? script.code : rest || null;

  variable = segments[0];

  if (segments[0] === segments[1]) {
    segments.shift();
  } else {
    variable += segments[1].toUpperCase();
  }

  name = 'dictionary-' + segments.join('-');

  if (rest) {
    variable += rest.charAt(0).toUpperCase() + rest.slice(1);
  }

  description = lang + ' (' + region;

  keywords = [
    'spelling',
    'myspell',
    'hunspell',
    'dictionary'
  ];

  keywords = keywords.concat(lang.toLowerCase().split(' '));
  keywords = keywords.concat(region.toLowerCase().split(' '));

  flag = (script && script.name) || rest || '';

  if (flag) {
    keywords.push(flag.toLowerCase());
    description += ', ' + flag.charAt(0).toUpperCase() + flag.slice(1);
  }

  description += ') spelling dictionary in UTF-8';

  keywords = keywords.filter(unique);

  template.name = name;
  template.version = pack.version || '1.0.0';
  template.description = description;
  template.license = spdx;
  template.keywords = keywords;
  template.repository = {
    type: 'git',
    url: 'https://github.com/wooorm/dictionaries'
  };
  template.bugs = 'https://github.com/wooorm/dictionaries/issues';
  template.author = 'Titus Wormer <tituswormer@gmail.com> ' +
    '(http://wooorm.com)';
  template.contributors = [
    'Titus Wormer <tituswormer@gmail.com> (http://wooorm.com)'
  ];
  template.main = 'index.js';
  template.files = [
    'index.js',
    'index.aff',
    'index.dic'
  ];

  readme = process(docs, template, source, variable, code, hasLicense);
  code = process(index, template, source, variable, code, hasLicense);

  write(join(base, 'readme.md'), readme);
  write(join(base, 'index.js'), code);
  write(join(base, 'package.json'), JSON.stringify(template, 0, 2) + '\n');
});

/* Process a template. */
function process(file, pack, source, variable, code, hasLicense) {
  var license = pack.license;

  if (hasLicense) {
    license = '[' + license + '](https://github.com/wooorm/' +
      'dictionaries/blob/master/dictionaries/' + code + '/LICENSE)';
  }

  return file
    .replace(/\{\{NAME\}\}/g, pack.name)
    .replace(/\{\{DESCRIPTION\}\}/g, pack.description)
    .replace(/\{\{SPDX\}\}/g, pack.license)
    .replace(/\{\{SOURCE\}\}/g, source)
    .replace(/\{\{VAR\}\}/g, variable)
    .replace(/\{\{CODE\}\}/g, code)
    .replace(/\{\{LICENSE\}\}/g, license);
}

/* Access a template. */
function template(fileName) {
  return join(__dirname, 'template', fileName);
}

/* Access a dictionary. */
function dict(code) {
  return join('dictionaries', code);
}

/* Check if value is unique. */
function unique(key, index, parent) {
  return parent.indexOf(key, index + 1) === -1;
}

function find(data, code) {
  var length = data.length;
  var index = -1;
  var entry;

  while (++index < length) {
    entry = data[index];

    if (entry.iso6392B === code || entry.iso6392T === code) {
      return entry;
    }
  }
}
