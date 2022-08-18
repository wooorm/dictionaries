<!-- lint disable no-html -->

# dictionaries

Collection of normalized and installable [hunspell][] dictionaries.

## Contents

*   [What is this?](#what-is-this)
*   [When should I use this?](#when-should-i-use-this)
*   [Install](#install)
*   [Use](#use)
*   [List of dictionaries](#list-of-dictionaries)
*   [Examples](#examples)
    *   [Example: use with `nspell`](#example-use-with-nspell)
    *   [Example: load files from ESM](#example-load-files-from-esm)
    *   [Example: load files from CommonJS](#example-load-files-from-commonjs)
    *   [Example: use with macOS](#example-use-with-macos)
*   [Types](#types)
*   [Contribute](#contribute)
    *   [Build](#build)
    *   [Updating a dictionary](#updating-a-dictionary)
    *   [Adding a new dictionary](#adding-a-new-dictionary)
*   [License](#license)

## What is this?

This monorepo is a bunch of scripts that crawls dictionaries from several
sources, normalizes them, and packs them so that they can each be installed and
used in one single way.
Dictionaries are not maintained here but they are usable from here.

## When should I use this?

You can particularly use the packages here as a programmer when integrating with
other tools (such as [`nodehun`][nodehun], [`nspell`][nspell]) or when making
such tools.

## Install

In Node.js (version 12.20+, 14.14+, or 16.0+), install with [npm][]:

```sh
npm install dictionary-en
```

> 👉 **Note**: replace `en` with the language code you want.
>
> ⚠️ **Important**: this project itself is MIT, but each `index.dic` and
> `index.aff` file still has its original license!

## Use

```js
import dictionaryEn from 'dictionary-en'

dictionaryEn(function (error, en) {
  if (error) throw error
  console.log(en)
  // To do: use `en` somehow
})
```

Yields:

```js
{dic: <Buffer>, aff: <Buffer>}
```

## List of dictionaries

> 👉 **Note**: preferred BCP-47 codes are used (according to Unicode CLDR).
> To illustrate, as American English and Brazilian Portuguese are the most
> common types of English and Portuguese respectively, they get the codes `en`
> and `pt`.

<!--support start-->

In total 92 dictionaries are provided.

| Name | Description | License |
| - | - | - |
| [`dictionary-bg`](dictionaries/bg) | Bulgarian | [(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)](dictionaries/bg/license) |
| [`dictionary-br`](dictionaries/br) | Breton | [(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)](dictionaries/br/license) |
| [`dictionary-ca`](dictionaries/ca) | Catalan | [(GPL-2.0 OR LGPL-2.1)](dictionaries/ca/license) |
| [`dictionary-ca-valencia`](dictionaries/ca-valencia) | Catalan (Valencian) | [(GPL-2.0 OR LGPL-2.1)](dictionaries/ca-valencia/license) |
| [`dictionary-cs`](dictionaries/cs) | Czech | [GPL-2.0](dictionaries/cs/license) |
| [`dictionary-cy`](dictionaries/cy) | Welsh | [LGPL-3.0](dictionaries/cy/license) |
| [`dictionary-da`](dictionaries/da) | Danish | [(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)](dictionaries/da/license) |
| [`dictionary-de`](dictionaries/de) | German | [(GPL-2.0 OR GPL-3.0)](dictionaries/de/license) |
| [`dictionary-de-at`](dictionaries/de-AT) | German (Austria) | [(GPL-2.0 OR GPL-3.0)](dictionaries/de-AT/license) |
| [`dictionary-de-ch`](dictionaries/de-CH) | German (Switzerland) | [(GPL-2.0 OR GPL-3.0)](dictionaries/de-CH/license) |
| [`dictionary-el`](dictionaries/el) | Modern Greek | [(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)](dictionaries/el/license) |
| [`dictionary-el-polyton`](dictionaries/el-polyton) | Modern Greek (Polytonic Greek) | [GPL-3.0](dictionaries/el-polyton/license) |
| [`dictionary-en`](dictionaries/en) | English | [(MIT AND BSD)](dictionaries/en/license) |
| [`dictionary-en-au`](dictionaries/en-AU) | English (Australia) | [(MIT AND BSD)](dictionaries/en-AU/license) |
| [`dictionary-en-ca`](dictionaries/en-CA) | English (Canada) | [(MIT AND BSD)](dictionaries/en-CA/license) |
| [`dictionary-en-gb`](dictionaries/en-GB) | English (United Kingdom) | [(MIT AND BSD)](dictionaries/en-GB/license) |
| [`dictionary-en-za`](dictionaries/en-ZA) | English (South Africa) | [LGPL-2.1](dictionaries/en-ZA/license) |
| [`dictionary-eo`](dictionaries/eo) | Esperanto | [GPL-2.0](dictionaries/eo/license) |
| [`dictionary-es`](dictionaries/es) | Spanish (or Castilian) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es/license) |
| [`dictionary-es-ar`](dictionaries/es-AR) | Spanish (or Castilian; Argentina) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-AR/license) |
| [`dictionary-es-bo`](dictionaries/es-BO) | Spanish (or Castilian; Bolivia) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-BO/license) |
| [`dictionary-es-cl`](dictionaries/es-CL) | Spanish (or Castilian; Chile) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-CL/license) |
| [`dictionary-es-co`](dictionaries/es-CO) | Spanish (or Castilian; Colombia) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-CO/license) |
| [`dictionary-es-cr`](dictionaries/es-CR) | Spanish (or Castilian; Costa Rica) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-CR/license) |
| [`dictionary-es-cu`](dictionaries/es-CU) | Spanish (or Castilian; Cuba) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-CU/license) |
| [`dictionary-es-do`](dictionaries/es-DO) | Spanish (or Castilian; Dominican Republic) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-DO/license) |
| [`dictionary-es-ec`](dictionaries/es-EC) | Spanish (or Castilian; Ecuador) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-EC/license) |
| [`dictionary-es-gt`](dictionaries/es-GT) | Spanish (or Castilian; Guatemala) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-GT/license) |
| [`dictionary-es-hn`](dictionaries/es-HN) | Spanish (or Castilian; Honduras) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-HN/license) |
| [`dictionary-es-mx`](dictionaries/es-MX) | Spanish (or Castilian; Mexico) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-MX/license) |
| [`dictionary-es-ni`](dictionaries/es-NI) | Spanish (or Castilian; Nicaragua) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-NI/license) |
| [`dictionary-es-pa`](dictionaries/es-PA) | Spanish (or Castilian; Panama) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-PA/license) |
| [`dictionary-es-pe`](dictionaries/es-PE) | Spanish (or Castilian; Peru) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-PE/license) |
| [`dictionary-es-ph`](dictionaries/es-PH) | Spanish (or Castilian; Philippines) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-PH/license) |
| [`dictionary-es-pr`](dictionaries/es-PR) | Spanish (or Castilian; Puerto Rico) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-PR/license) |
| [`dictionary-es-py`](dictionaries/es-PY) | Spanish (or Castilian; Paraguay) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-PY/license) |
| [`dictionary-es-sv`](dictionaries/es-SV) | Spanish (or Castilian; El Salvador) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-SV/license) |
| [`dictionary-es-us`](dictionaries/es-US) | Spanish (or Castilian; United States) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-US/license) |
| [`dictionary-es-uy`](dictionaries/es-UY) | Spanish (or Castilian; Uruguay) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-UY/license) |
| [`dictionary-es-ve`](dictionaries/es-VE) | Spanish (or Castilian; Venezuela) | [(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)](dictionaries/es-VE/license) |
| [`dictionary-et`](dictionaries/et) | Estonian | LGPL-2.1 |
| [`dictionary-eu`](dictionaries/eu) | Basque | GPL-2.0 |
| [`dictionary-fa`](dictionaries/fa) | Persian | [Apache-2.0](dictionaries/fa/license) |
| [`dictionary-fo`](dictionaries/fo) | Faroese | [(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)](dictionaries/fo/license) |
| [`dictionary-fr`](dictionaries/fr) | French | [MPL-2.0](dictionaries/fr/license) |
| [`dictionary-fur`](dictionaries/fur) | Friulian | [GPL-2.0](dictionaries/fur/license) |
| [`dictionary-fy`](dictionaries/fy) | Western Frisian | [GPL-3.0](dictionaries/fy/license) |
| [`dictionary-ga`](dictionaries/ga) | Irish | [GPL-2.0](dictionaries/ga/license) |
| [`dictionary-gd`](dictionaries/gd) | Scottish Gaelic (or Gaelic) | [GPL-3.0](dictionaries/gd/license) |
| [`dictionary-gl`](dictionaries/gl) | Galician | [GPL-3.0](dictionaries/gl/license) |
| [`dictionary-he`](dictionaries/he) | Hebrew | [AGPL-3.0](dictionaries/he/license) |
| [`dictionary-hr`](dictionaries/hr) | Croatian | [(LGPL-2.1 OR SISSL)](dictionaries/hr/license) |
| [`dictionary-hu`](dictionaries/hu) | Hungarian | [(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)](dictionaries/hu/license) |
| [`dictionary-hy`](dictionaries/hy) | Armenian | [(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)](dictionaries/hy/license) |
| [`dictionary-hyw`](dictionaries/hyw) | Western Armenian | [(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)](dictionaries/hyw/license) |
| [`dictionary-ia`](dictionaries/ia) | Interlingua | [GPL-3.0](dictionaries/ia/license) |
| [`dictionary-ie`](dictionaries/ie) | Interlingue (or Occidental) | [Apache-2.0](dictionaries/ie/license) |
| [`dictionary-is`](dictionaries/is) | Icelandic | [CC-BY-SA-3.0](dictionaries/is/license) |
| [`dictionary-it`](dictionaries/it) | Italian | [GPL-3.0](dictionaries/it/license) |
| [`dictionary-ka`](dictionaries/ka) | Georgian | [MIT](dictionaries/ka/license) |
| [`dictionary-ko`](dictionaries/ko) | Korean | [(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)](dictionaries/ko/license) |
| [`dictionary-la`](dictionaries/la) | Latin | [GPL-2.0](dictionaries/la/license) |
| [`dictionary-lb`](dictionaries/lb) | Luxembourgish (or Letzeburgesch) | [EUPL-1.1](dictionaries/lb/license) |
| [`dictionary-lt`](dictionaries/lt) | Lithuanian | [BSD-3-Clause](dictionaries/lt/license) |
| [`dictionary-ltg`](dictionaries/ltg) | Latgalian | [LGPL-2.1](dictionaries/ltg/license) |
| [`dictionary-lv`](dictionaries/lv) | Latvian | [LGPL-2.1](dictionaries/lv/license) |
| [`dictionary-mk`](dictionaries/mk) | Macedonian | [GPL-3.0](dictionaries/mk/license) |
| [`dictionary-mn`](dictionaries/mn) | Mongolian | [LPPL-1.3c](dictionaries/mn/license) |
| [`dictionary-nb`](dictionaries/nb) | Norwegian Bokmål | [GPL-2.0](dictionaries/nb/license) |
| [`dictionary-nds`](dictionaries/nds) | Low German (or Low Saxon) | [GPL-3.0](dictionaries/nds/license) |
| [`dictionary-ne`](dictionaries/ne) | Nepali | [LGPL-2.1](dictionaries/ne/license) |
| [`dictionary-nl`](dictionaries/nl) | Dutch (or Flemish) | [(BSD-3-Clause OR CC-BY-3.0)](dictionaries/nl/license) |
| [`dictionary-nn`](dictionaries/nn) | Norwegian Nynorsk | [GPL-2.0](dictionaries/nn/license) |
| [`dictionary-oc`](dictionaries/oc) | Occitan (post 1500) | [GPL-2.0](dictionaries/oc/license) |
| [`dictionary-pl`](dictionaries/pl) | Polish | [(GPL-3.0 OR LGPL-3.0 OR MPL-2.0)](dictionaries/pl/license) |
| [`dictionary-pt`](dictionaries/pt) | Portuguese | [(LGPL-3.0 OR MPL-2.0)](dictionaries/pt/license) |
| [`dictionary-pt-pt`](dictionaries/pt-PT) | Portuguese (Portugal) | [(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)](dictionaries/pt-PT/license) |
| [`dictionary-ro`](dictionaries/ro) | Romanian (or Moldavian; or Moldovan) | [(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)](dictionaries/ro/license) |
| [`dictionary-ru`](dictionaries/ru) | Russian | [LGPL-3.0](dictionaries/ru/license) |
| [`dictionary-rw`](dictionaries/rw) | Kinyarwanda | [GPL-3.0](dictionaries/rw/license) |
| [`dictionary-sk`](dictionaries/sk) | Slovak | [(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)](dictionaries/sk/license) |
| [`dictionary-sl`](dictionaries/sl) | Slovenian | [(GPL-3.0 OR LGPL-2.1)](dictionaries/sl/license) |
| [`dictionary-sr`](dictionaries/sr) | Serbian | [(GPL-2.0 OR LGPL-2.1 OR MPL-1.1 OR CC-BY-SA-3.0)](dictionaries/sr/license) |
| [`dictionary-sr-latn`](dictionaries/sr-Latn) | Serbian (Latin script) | [(GPL-2.0 OR LGPL-2.1 OR MPL-1.1 OR CC-BY-SA-3.0)](dictionaries/sr-Latn/license) |
| [`dictionary-sv`](dictionaries/sv) | Swedish | [LGPL-3.0](dictionaries/sv/license) |
| [`dictionary-sv-fi`](dictionaries/sv-FI) | Swedish (Finland) | [LGPL-3.0](dictionaries/sv-FI/license) |
| [`dictionary-tk`](dictionaries/tk) | Turkmen | [Apache-2.0](dictionaries/tk/license) |
| [`dictionary-tlh`](dictionaries/tlh) | Klingon (or tlhIngan Hol) | [Apache-2.0](dictionaries/tlh/license) |
| [`dictionary-tlh-latn`](dictionaries/tlh-Latn) | Klingon (or tlhIngan Hol; Latin script) | [Apache-2.0](dictionaries/tlh-Latn/license) |
| [`dictionary-tr`](dictionaries/tr) | Turkish | [MIT](dictionaries/tr/license) |
| [`dictionary-uk`](dictionaries/uk) | Ukrainian | [GPL-3.0](dictionaries/uk/license) |
| [`dictionary-vi`](dictionaries/vi) | Vietnamese | [GPL-2.0](dictionaries/vi/license) |

<!--support end-->

## Examples

### Example: use with `nspell`

This example uses `dictionary-en` in combination with [`nspell`][nspell].

<details><summary>Show install command for this example</summary>

```sh
npm install dictionary-en nspell
```

</details>

```js
import dictionaryEn from 'dictionary-en'
import nspell from 'nspell'

dictionaryEn(function (error, en) {
  if (error) throw error
  const spell = nspell(en)
  console.log(spell.correct('color'))
  console.log(spell.correct('colour'))
})
```

Yields:

```txt
true
false
```

### Example: load files from ESM

This example loads the `index.dic` and `index.aff` files located in
`dictionary-hyw` (Western Armenian) from a Node.js JavaScript module (ESM).

It uses a ponyfill ([`import-meta-resolve`][import-meta-resolve]) for an
experimental Node API.

<details><summary>Show install command for this example</summary>

```sh
npm install dictionary-hyw import-meta-resolve
```

</details>

```js
import fs from 'node:fs/promises'
import {resolve} from 'import-meta-resolve'

const base = await resolve('dictionary-hyw', import.meta.url)
const dic = await fs.readFile(new URL('index.dic', base))
const aff = await fs.readFile(new URL('index.aff', base))
console.log(dic, aff)
```

### Example: load files from CommonJS

This example loads the `index.dic` and `index.aff` files located in
`dictionary-tlh` (Klingon) from a Node.js CommonJS script (CJS).

<details><summary>Show install command for this example</summary>

```sh
npm install dictionary-tlh
```

</details>

```js
const fs = require('node:fs')
const path = require('node:path')

const base = require.resolve('dictionary-tlh')
const dic = await fs.readFile(path.join(base, 'index.dic'))
const aff = await fs.readFile(path.join(base, 'index.aff'))
console.log(dic, aff)
```

<!--Old name of the following section:-->

<a name="macos"></a>

### Example: use with macOS

Follow these steps to use a dictionary on macOS:

1.  Navigate to the dictionary you want on GitHub, such as `dictionaries/$code`
    (replace `$code` with the language code you want)
2.  Download the `index.aff` and `index.dic` files (i.e., open them, right-click
    “Raw”, and “download linked files”)
3.  Rename the download files to `$code.aff` and `$code.dic`
4.  Move `$code.aff` and `$code.dic` into the folder `~/Library/Spelling/`
5.  Go to **System Preferences** > **Keyboard** > **Text** > **Spelling** and
    select your added language (it should come with the `(Library)` suffix and
    is situated at the bottom)

## Types

The dictionaries are typed with [TypeScript][].

## Contribute

Yes please!
See [How to Contribute to Open Source][contribute].

### Build

To build this project, on macOS, you at least need to install:

*   **wget**: `brew install wget` (crawling)
*   **hunspell**: `brew install hunspell` (many dictionaries)
*   **sed**: `brew install gnu-sed` (crawling, many dictionaries)
*   **coreutils**: `brew install coreutils` (many dictionaries)
*   **ispell**: `brew install ispell` (German)

> 👉 **Note**: sed and the GNU replacements should be setup in PATH to overwrite
> macOS defaults.

### Updating a dictionary

Dictionaries are not maintained here.
Report problems upstream.

### Adding a new dictionary

Dictionaries are not maintained here.
Most languages have a small community or institute that maintains a dictionary,
and they often do so on GitHub or similar.
Please ask in the issues to request that such a dictionary is included here.

> 👉 **Note**: acceptable dictionaries must:
>
> *   have a significant affix file (not just a `.dic` file)
> *   have an open source license
> *   have recent contributions

## License

[MIT][] © [Titus Wormer][author]

See `license` files in each dictionary for the licensing of `index.dic` and
`index.aff` files.

[npm]: https://docs.npmjs.com/cli/install

[hunspell]: https://hunspell.github.io

[nodehun]: https://github.com/nathanjsweet/nodehun

[nspell]: https://github.com/wooorm/nspell

[mit]: license

[author]: https://wooorm.com

[typescript]: https://www.typescriptlang.org

[contribute]: https://opensource.guide/how-to-contribute/

[import-meta-resolve]: https://github.com/wooorm/import-meta-resolve
