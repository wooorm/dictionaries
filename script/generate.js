/**
 * @author Titus Wormer
 * @copyright 2015 Titus Wormer
 * @license MIT
 * @module dictionary:generate
 * @fileoverview Generate dictionary files.
 */

'use strict';

/*
 * Dependencies.
 */

var fs = require('fs');
var path = require('path');
var hidden = require('is-hidden');
var iso6391 = require('langs');
var iso6392 = require('iso-639-2');
var iso3166 = require('iso-3166-1-alpha-2');
var iso15924 = require('iso-15924');

/*
 * Methods.
 */

var dir = fs.readdirSync;
var exists = fs.existsSync;
var read = fs.readFileSync;
var write = fs.writeFileSync;
var join = path.join;

/**
 * Access a template.
 *
 * @param {string} fileName - Name.
 * @return {string} - File-path.
 */
function template(fileName) {
    return join(__dirname, 'template', fileName);
}

/**
 * Access a dictionary.
 *
 * @param {string} code - Dictionary code.
 * @return {string} - File-path.
 */
function dict(code) {
    return join('dictionaries', code);
}

/**
 * Check if a file is visible.
 *
 * @param {string} fileName - Name.
 * @return {boolean} - Whether `fileName` is visible.
 */
function visible(fileName) {
    return !hidden(fileName);
}

/**
 * Check if value is not repeat after itself in its parent.
 *
 * @param {string} key - Value.
 * @param {number} index - Position of `key` in `parent`.
 * @param {Array.<*>} parent - Parent of `key`.
 * @return {boolean} - Whether `key` is unique in `parent`.
 */
function unique(key, index, parent) {
    return parent.indexOf(key, index + 1) === -1;
}

/**
 * Process a template.
 *
 * @param {string} file - File to process.
 * @param {Object} pack - Package file.
 * @param {string} source - Location of dictionary.
 * @param {string} variable - JavaScript name of module.
 * @param {string} code - Short-code for dictionary.
 * @return {string} - Processed `file`.
 */
function process(file, pack, source, variable, code) {
    return file
        .replace(/\{\{NAME\}\}/g, pack.name)
        .replace(/\{\{DESCRIPTION\}\}/g, pack.description)
        .replace(/\{\{SPDX\}\}/g, pack.license)
        .replace(/\{\{SOURCE\}\}/g, source)
        .replace(/\{\{VAR\}\}/g, variable)
        .replace(/\{\{CODE\}\}/g, code);
}

/*
 * Constants.
 */

var documentation = read(template('readme.md'), 'utf-8');
var index = read(template('index.js'), 'utf-8');

/*
 * Generate.
 */

dir('dictionaries').filter(visible).sort().forEach(function (code) {
    var base = dict(code);
    var template = {};
    var source = read(join(base, 'SOURCE'), 'utf-8').trim();
    var spdx = read(join(base, 'SPDX'), 'utf-8').trim();
    var segments = code.toLowerCase().replace(/[^a-z]+/g, '-').split('-');
    var lang = iso6391.where('1', segments[0]) || iso6392.get(segments[0]);
    var region = iso3166.getCountry(segments[1].toUpperCase());
    var rest = segments[2];
    var script = rest && iso15924.get(rest);
    var variable;
    var readme;
    var pack;
    var name;
    var keywords;
    var description;
    var flag;

    if (exists(join(base, 'package.json'))) {
        pack = JSON.parse(read(join(base, 'package.json')));
    } else {
        pack = {};
    }

    lang = lang ? lang.name : null;
    script = script ? script.name : null;

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

    flag = script || rest || '';

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
    template.repository = 'wooorm/dictionary';
    template.author = 'Titus Wormer <tituswormer@gmail.com>';
    template.main = 'index.js';
    template.files = [
        'index.js',
        'index.aff',
        'index.dic'
    ];

    readme = process(documentation, template, source, variable, code);
    code = process(index, template, source, variable, code);

    write(join(base, 'readme.md'), readme);
    write(join(base, 'index.js'), code);
    write(join(base, 'package.json'), JSON.stringify(template, 0, 2) + '\n');
});
