#!/bin/sh
ARCHIVES="archive"
SOURCES="source"
UNCRAWLABLES="uncrawlable"
DICTIONARIES="dictionaries"

mkdir -p "$ARCHIVES"
mkdir -p "$SOURCES"
mkdir -p "$DICTIONARIES"
mkdir -p "$UNCRAWLABLES"

#####################################################################
# METHODS ###########################################################
#####################################################################

#
# Unpack an archive.
#
# @param $1 - Name of archive.
# @param $2 - Page of source.
# @param $3 - Path to archive.
#
unpack() {
  sourcePath="$SOURCES/$1"

  if [ ! -e "$sourcePath" ]; then
    filename=$(basename "$3")
    extension="${filename#*.}"

    if [ "$extension" = "tar.bz2" ]; then
      mkdir -p "$sourcePath"
      tar xvjf "$3" -C "$sourcePath" --strip-components=1
    else
      unzip "$3" -d "$sourcePath"
    fi

    echo "$2" > "$sourcePath/SOURCE"
  fi
}

#
# Crawl and unpack an archive.
#
# @param $1 - Name of archive;
# @param $2 - Page of source.
# @param $3 - URL to archive.
#
crawl() {
  filename=$(basename "$3")
  extension="${filename#*.}"
  archivePath="$ARCHIVES/$1.zip"

  if [ "$extension" = "tar.bz2" ]; then
    archivePath="$ARCHIVES/$1.tar.bz2"
  fi

  if [ ! -e "$archivePath" ]; then
    wget "$3" -O "$archivePath"
  fi

  unpack "$1" "$2" "$archivePath"
}

#
# Copy a local archive and unpack it.
#
# @param $1 - Name of archive.
# @param $2 - Page of source.
#
uncrawl() {
  archivePath="$ARCHIVES/$1.zip"

  if [ ! -e "$archivePath" ]; then
    cp "$UNCRAWLABLES/$1.zip" "$archivePath"
  fi

  unpack "$1" "$2" "$archivePath"

  echo "Warning: Loading local $1"
}

#
# Generate a package from a crawled directory (at $1) and
# the given settings.
#
# @param $1 - Name of source
# @param $2 - Language / region code
# @param $3 - SPDX license
# @param $4 - Path to license file. Should be `-` when not applicable
# @param $5 - Path to `.dic` file
# @param $6 - Path to `.aff` file
# @param $7 - Encoding of `.dic` file
# @param $7 - Encoding of `.aff` file (defaults to $7)
#
generate() {
  SOURCE="$SOURCES/$1"
  dictionary="$DICTIONARIES/$2"
  dicEnc="$7"
  affEnc="$8"

  mkdir -p "$dictionary"

  cp "$SOURCE/SOURCE" "$dictionary/SOURCE"

  echo "$3" > "$dictionary/SPDX"

  if [ -e "$SOURCE/$4" ]; then
    tr -d '\r' < "$SOURCE/$4" > "$dictionary/LICENSE"
  else
    echo "Warning: Missing LICENSE file for $2"
  fi

  if [ "$affEnc" = "" ]; then
    affEnc="$dicEnc"
  fi
  
  (iconv -f "$dicEnc" -t "UTF-8" | tr -d '\r') < "$SOURCE/$5" > "$dictionary/index.dic"
  (iconv -f "$affEnc" -t "UTF-8" | sed "s/SET .*/SET UTF-8/" | tr -d '\r') < "$SOURCE/$6" > "$dictionary/index.aff"
}

#####################################################################
# ARCHIVES ##########################################################
#####################################################################

#
# List of archives to crawl.
#

crawl "libreoffice" \
  "https://github.com/LibreOffice/dictionaries" \
  "https://github.com/LibreOffice/dictionaries/archive/master.zip"
crawl "basque" \
  "http://extensions.openoffice.org/en/project/xuxen-basque-spell-checking-dictionary" \
  "http://sourceforge.net/projects/aoo-extensions/files/1383/2/xuxen_4_ooo3.oxt/download"
crawl "bulgarian" \
  "http://extensions.openoffice.org/en/project/bulgarian-dictionaries-blgarski-rechnici" \
  "http://sourceforge.net/projects/aoo-extensions/files/744/8/dictionaries-bg.oxt/download"
crawl "catalan" \
  "http://extensions.openoffice.org/en/project/catalan-dictionary-pack-spell-checker-hyphenation-patterns-and-thesaurus" \
  "http://sourceforge.net/projects/aoo-extensions/files/1205/5/ca.3.0.0.oxt/download"
crawl "croatian" \
  "http://extensions.openoffice.org/en/project/croatian-dictionary-and-hyphenation-patterns" \
  "http://sourceforge.net/projects/aoo-extensions/files/1052/2/dict-hr.oxt/download"
crawl "czech" \
  "http://extensions.openoffice.org/en/project/czech-dictionary-pack-ceske-slovniky-cs-cz" \
  "http://sourceforge.net/projects/aoo-extensions/files/1078/0/dict-cs-2.0.oxt/download"
crawl "danish" \
  "http://www.stavekontrolden.dk" \
  "http://www.stavekontrolden.dk/main/top/extension/dict-da-current.oxt"
crawl "dutch" \
  "http://extensions.openoffice.org/en/project/dutch-spelling-and-hyphenation-dictionary" \
  "http://sourceforge.net/projects/aoo-extensions/files/1456/6/nl-dict-v2.00g.oxt/download"
crawl "english" \
  "http://extensions.openoffice.org/en/project/english-dictionaries-apache-openoffice" \
  "https://sourceforge.net/projects/aoo-extensions/files/17102/35/dict-en-20170701.oxt/download"
crawl "english-gb" \
  "http://wordlist.aspell.net/dicts/" \
  "https://downloads.sourceforge.net/project/wordlist/speller/2017.01.22/hunspell-en_GB-ise-2017.01.22.zip"
crawl "english-american" \
  "http://wordlist.aspell.net/dicts/" \
  "https://downloads.sourceforge.net/project/wordlist/speller/2017.01.22/hunspell-en_US-2017.01.22.zip"
crawl "english-canadian" \
  "http://wordlist.aspell.net/dicts/" \
  "https://downloads.sourceforge.net/project/wordlist/speller/2017.01.22/hunspell-en_CA-2017.01.22.zip"
crawl "english-australian" \
  "http://wordlist.aspell.net/dicts/" \
  "https://downloads.sourceforge.net/project/wordlist/speller/2017.01.22/hunspell-en_AU-2017.01.22.zip"
crawl "french" \
  "https://www.dicollecte.org" \
  "http://www.dicollecte.org/grammalecte/oxt/Grammalecte-fr-v0.5.18.oxt"
crawl "galician" \
  "http://extensions.openoffice.org/en/project/corrector-ortografico-hunspell-para-galego" \
  "http://sourceforge.net/projects/aoo-extensions/files/5660/1/hunspell-gl-13.10.oxt/download"
crawl "german" \
  "https://www.j3e.de/ispell/igerman98/index_en.html" \
  "https://www.j3e.de/ispell/igerman98/dict/igerman98-20161207.tar.bz2"
crawl "greek" \
  "http://www.elspell.gr" \
  "https://github.com/stevestavropoulos/elspell/archive/master.zip"
# Disabled due to unknown encoding.
# crawl "hungarian" \
#    "http://extensions.openoffice.org/en/project/hungarian-dictionary-pack" \
#    "http://sourceforge.net/projects/aoo-extensions/files/1283/9/dict-hu.oxt/download"
crawl "irish" \
  "http://borel.slu.edu/ispell/index-en.html" \
  "https://github.com/kscanne/gaelspell/archive/master.zip"
crawl "italian" \
  "http://extensions.openoffice.org/en/project/italian-dictionary-thesaurus-hyphenation-patterns" \
  "http://sourceforge.net/projects/aoo-extensions/files/1204/13/dict-it.oxt/download"
crawl "kinyarwanda" \
  "https://github.com/kscanne/hunspell-rw" \
  "https://github.com/kscanne/hunspell-rw/archive/master.zip"
uncrawl "luxembourgish" \
  "http://extensions.openoffice.org/en/project/luxembourgish-dictionary-and-thesaurus"
crawl "mongolian" \
  "http://extensions.openoffice.org/en/project/mongol-helniy-ugiyn-aldaa-shalgagch-ueer-taslagch-mongolian-spelling-and-hyphenation" \
  "http://sourceforge.net/projects/aoo-extensions/files/3204/2/dict-mn.oxt/download"
crawl "norwegian" \
  "http://extensions.openoffice.org/en/project/norwegian-dictionaries-spell-checker-thesaurus-and-hyphenation" \
  "http://sourceforge.net/projects/aoo-extensions/files/1216/6/dictionary-no-no-2.1.oxt/download"
crawl "polish" \
  "http://extensions.openoffice.org/en/project/polish-dictionary-pack" \
  "http://sourceforge.net/projects/aoo-extensions/files/806/4/pl-dict.oxt/download"
crawl "portuguese-br" \
  "http://extensions.openoffice.org/en/project/vero-brazilian-portuguese-spellchecking-dictionary-hyphenator" \
  "http://sourceforge.net/projects/aoo-extensions/files/1375/8/vero_pt_br_v208aoc.oxt/download"
crawl "portuguese-eu" \
  "http://extensions.openoffice.org/en/project/european-portuguese-dictionaries" \
  "http://sourceforge.net/projects/aoo-extensions/files/1196/35/oo3x-pt-pt-15.7.4.1.oxt/download"
crawl "romanian" \
  "http://extensions.openoffice.org/en/project/romanian-dictionary-pack-spell-checker-hyphenation-thesaurus" \
  "http://sourceforge.net/projects/aoo-extensions/files/1392/10/dict-ro.1.7.oxt/download"
crawl "russian" \
  "http://extensions.openoffice.org/en/project/russian-dictionary" \
  "http://sourceforge.net/projects/aoo-extensions/files/936/9/dict_ru_ru-0.6.oxt/download"
crawl "serbian" \
  "http://extensions.openoffice.org/en/project/serbian-cyrillic-and-latin-spelling-and-hyphenation" \
  "http://sourceforge.net/projects/aoo-extensions/files/1572/9/dict-sr.oxt/download"
crawl "slovak" \
  "http://extensions.openoffice.org/en/project/slovak-dictionary-package-slovenske-slovniky" \
  "http://sourceforge.net/projects/aoo-extensions/files/1143/11/dict-sk.oxt/download"
crawl "slovenian" \
  "http://extensions.openoffice.org/en/project/slovenian-dictionary-package-slovenski-paket-slovarjev" \
  "http://sourceforge.net/projects/aoo-extensions/files/3280/9/pack-sl.oxt/download"
crawl "spanish" \
  "http://extensions.openoffice.org/en/project/spanish-espanol" \
  "http://sourceforge.net/projects/aoo-extensions/files/2979/3/es_es.oxt/download"
crawl "swedish" \
  "http://extensions.openoffice.org/en/project/swedish-dictionaries-apache-openoffice" \
  "http://sourceforge.net/projects/aoo-extensions/files/5959/1/dict-sv.oxt/download"
crawl "turkish" \
  "http://extensions.openoffice.org/en/project/turkish-spellcheck-dictionary" \
  "http://sourceforge.net/projects/aoo-extensions/files/18079/3/oo-turkish-dict-v1.2.oxt/download"
crawl "ukrainian" \
  "http://extensions.openoffice.org/en/project/ukrainian-dictionary" \
  "http://sourceforge.net/projects/aoo-extensions/files/975/6/dict-uk_ua-1.7.1.oxt/download"
crawl "vietnamese" \
  "http://extensions.openoffice.org/en/project/vietnamese-spellchecker" \
  "http://sourceforge.net/projects/aoo-extensions/files/917/3/vi_spellchecker_ooo3.oxt/download"

#####################################################################
# BUILD #############################################################
#####################################################################

cd "source/german"
make hunspell-all
cd ../..

cd "source/greek/elspell-master"
make
cd ../../..

cd "source/irish/gaelspell-master"
make ga_IE.dic ga_IE.aff
cd ../../..

cd "source/kinyarwanda/hunspell-rw-master"
make
cd ../../..

#####################################################################
# DICTIONARIES ######################################################
#####################################################################

#
# German (Austrian).
#

generate "german" \
  "de_AT" \
  "(GPL-2.0 OR GPL-3.0)" \
  "hunspell/Copyright" \
  "hunspell/de_AT.dic" \
  "hunspell/de_AT.aff" \
  "ISO8859-1"

#
# Basque.
#

generate "basque" \
  "eu_ES" \
  "GPL-2.0" \
  "-" \
  "dictionaries/eu.dic" \
  "dictionaries/eu.aff" \
  "ISO8859-1"

#
# Bulgarian.
#

generate "bulgarian" \
  "bg_BG" \
  "LGPL-2.1" \
  "README.txt" \
  "spell/bg_BG.dic" \
  "spell/bg_BG.aff" \
  "CP1251"

#
# Catalan / Valencian.
#

generate "catalan" \
  "ca_ES" \
  "LGPL-2.0" \
  "LICENSES-en.txt" \
  "ca.dic" \
  "ca.aff" \
  "UTF-8"

generate "catalan" \
  "ca_ES-valencia" \
  "LGPL-2.0" \
  "LICENSES-en.txt" \
  "ca-ES-valencia.dic" \
  "ca-ES-valencia.aff" \
  "UTF-8"

#
# Croatian.
#

generate "croatian" \
  "hr_HR" \
  "GPL-3.0" \
  "registration/license_hr.txt" \
  "hr_HR.dic" \
  "hr_HR.aff" \
  "ISO8859-2"
#
# Czech.
#

generate "czech" \
  "cs_CZ" \
  "GPL-2.0" \
  "README_en.txt" \
  "cs_CZ.dic" \
  "cs_CZ.aff" \
  "ISO8859-2"

#
# Danish.
#

generate "danish" \
  "da_DK" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" \
  "README_da_DK.txt" \
  "da_DK.dic" \
  "da_DK.aff" \
  "UTF-8"

#
# Dutch.
#

generate "dutch" \
  "nl_NL" \
  "(BSD-3-Clause OR CC-BY-3.0)" \
  "license_en_EN.txt" \
  "nl_NL.dic" \
  "nl_NL.aff" \
  "UTF-8"

#
# South African English.
#

generate "english" \
  "en_ZA" \
  "LGPL-2.1" \
  "README_en_ZA.txt" \
  "en_ZA.dic" \
  "en_ZA.aff" \
  "UTF-8"

#
# Note that “the Hunspell English Dictionaries” are very vaguely licensed.
# Read more in the license file. Note that the SPDX “(MIT AND BSD)”
# comes from aspell’s description as “BSD/MIT-like”.
#
# See: http://wordlist.aspell.net/other-dicts/#official
#

generate "english-canadian" \
  "en_CA" \
  "(MIT AND BSD)" \
  "README_en_CA.txt" \
  "en_CA.dic" \
  "en_CA.aff" \
  "UTF-8"

generate "english-american" \
  "en_US" \
  "(MIT AND BSD)" \
  "README_en_US.txt" \
  "en_US.dic" \
  "en_US.aff" \
  "UTF-8"

generate "english-gb" \
  "en_GB" \
  "(MIT AND BSD)" \
  "README_en_GB-ise.txt" \
  "en_GB-ise.dic" \
  "en_GB-ise.aff" \
  "UTF-8"

generate "english-australian" \
  "en_AU" \
  "(MIT AND BSD)" \
  "README_en_AU.txt" \
  "en_AU.dic" \
  "en_AU.aff" \
  "UTF-8"

#
# Icelandic.
#

generate "libreoffice" \
  "is_IS" \
  "CC-BY-SA-3.0" \
  "dictionaries-master/is/license.txt" \
  "dictionaries-master/is/is.dic" \
  "dictionaries-master/is/is.aff" \
  "UTF-8"

#
# French.
#

generate "french" \
  "fr_FR" \
  "MPL-2.0" \
  "dictionaries/README_dict_fr.txt" \
  "dictionaries/fr-classique.dic" \
  "dictionaries/fr-classique.aff" \
  "UTF-8"

#
# Galician.
#

generate "galician" \
  "gl_ES" \
  "GPL-3.0" \
  "license.txt" \
  "gl_ES.dic" \
  "gl_ES.aff" \
  "UTF-8"

#
# German (Germany).
#

generate "german" \
  "de_DE" \
  "(GPL-2.0 OR GPL-3.0)" \
  "hunspell/Copyright" \
  "hunspell/de_DE.dic" \
  "hunspell/de_DE.aff" \
  "ISO8859-1"

#
# Greek.
#

generate "greek" \
  "el_GR" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" \
  "elspell-master/myspell/README_el_GR.txt" \
  "elspell-master/myspell/el_GR.dic" \
  "elspell-master/myspell/el_GR.aff" \
  "UTF-8" \
  "UTF-8"

#
# Irish.
#

generate "irish" \
  "ga_IE" \
  "GPL-2.0" \
  "gaelspell-master/LICENSES-en.txt" \
  "gaelspell-master/ga_IE.dic" \
  "gaelspell-master/ga_IE.aff" \
  "UTF-8" \
  "UTF-8"

#
# Italian.
#

generate "italian" \
  "it_IT" \
  "GPL-3.0" \
  "dictionaries/README.txt" \
  "dictionaries/it_IT.dic" \
  "dictionaries/it_IT.aff" \
  "ISO8859-15"

#
# Kinyarwanda.
#

generate "kinyarwanda" \
  "rw_RW" \
  "GPL-3.0" \
  "hunspell-rw-master/LICENSE" \
  "hunspell-rw-master/rw_RW.dic" \
  "hunspell-rw-master/rw_RW.aff" \
  "UTF-8" \
  "ISO8859-1"

#
# Luxembourgish.
#

generate "luxembourgish" \
  "lb_LU" \
  "EUPL-1.1" \
  "registration/README_lb_LU.txt" \
  "lb_LU.dic" \
  "lb_LU.aff" \
  "ISO8859-1"

#
# Mongolian.
#

generate "mongolian" \
  "mn_MN" \
  "GPL-2.0" \
  "README_mn_MN.txt" \
  "mn_MN.dic" \
  "mn_MN.aff" \
  "UTF-8"

#
# Norwegian (Bokmal, Nynorsk).
#

generate "norwegian" \
  "nb_NO" \
  "GPL-2.0" \
  "COPYING" \
  "DICT/nb_NO.dic" \
  "DICT/nb_NO.aff" \
  "ISO8859-1"

generate "norwegian" \
  "nn_NO" \
  "GPL-2.0" \
  "COPYING" \
  "DICT/nn_NO.dic" \
  "DICT/nn_NO.aff" \
  "ISO8859-1"

#
# Polish.
#

generate "polish" \
  "pl_PL" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-2.0)" \
  "README_en.txt" \
  "pl_PL.dic" \
  "pl_PL.aff" \
  "ISO8859-2"

#
# Portuguese (Brazillian).
#

generate "portuguese-br" \
  "pt_BR" \
  "LGPL-2.1" \
  "README_en.TXT" \
  "pt_BR.dic" \
  "pt_BR.aff" \
  "ISO8859-1"

#
# Portuguese (European).
#

generate "portuguese-eu" \
  "pt_PT" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" \
  "dictionaries/README_pt_PT.txt" \
  "dictionaries/pt_PT.dic" \
  "dictionaries/pt_PT.aff" \
  "UTF-8"

#
# Romanian.
#

generate "romanian" \
  "ro_RO" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" \
  "README_EN.txt" \
  "ro_RO.dic" \
  "ro_RO.aff" \
  "UTF-8"

#
# Russian.
#

generate "russian" \
  "ru_RU" \
  "BSD-2-Clause" \
  "LICENSE" \
  "ru_RU.dic" \
  "ru_RU.aff" \
  "KOI8-R"

#
# Serbian.
#

generate "serbian" \
  "sr_RS-Latn" \
  "LGPL-3.0" \
  "registration/license_en-US.txt" \
  "sr-Latn.dic" \
  "sr-Latn.aff" \
  "UTF-8"

generate "serbian" \
  "sr_RS" \
  "LGPL-3.0" \
  "registration/license_en-US.txt" \
  "sr.dic" \
  "sr.aff" \
  "UTF-8"

#
# Slovak.
#

generate "slovak" \
  "sk_SK" \
  "GPL-2.0" \
  "LICENSE.txt" \
  "sk_SK/sk_SK.dic" \
  "sk_SK/sk_SK.aff" \
  "UTF-8"

#
# Slovenian.
#

generate "slovenian" \
  "sl_SI" \
  "(GPL-3.0 OR LGPL-2.1)" \
  "README_sl_SI.txt" \
  "sl_SI.dic" \
  "sl_SI.aff" \
  "ISO8859-2"

#
# Spanish.
#

generate "spanish" \
  "es_ES" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" \
  "README.txt" \
  "es_ES.dic" \
  "es_ES.aff" \
  "ISO8859-1"

#
# Swedish.
#

generate "swedish" \
  "sv_SE" \
  "LGPL-3.0" \
  "LICENSE_en_US.txt" \
  "sv_SE.dic" \
  "sv_SE.aff" \
  "UTF-8"

#
# German (Switzerland).
#

generate "german" \
  "de_CH" \
  "(GPL-2.0 OR GPL-3.0)" \
  "hunspell/Copyright" \
  "hunspell/de_CH.dic" \
  "hunspell/de_CH.aff" \
  "ISO8859-1"

#
# Turkish.
#

# Unknown license.
generate "turkish" \
  "tr-TR" \
  "MIT" \
  "-" \
  "dictionaries/tr-TR.dic" \
  "dictionaries/tr-TR.aff" \
  "UTF-8"

#
# Ukrainian.
#

generate "ukrainian" \
  "uk_UA" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" \
  "uk_UA/README_uk_UA.txt" \
  "uk_UA/uk_UA.dic" \
  "uk_UA/uk_UA.aff" \
  "UTF-8"

#
# Vietnamese.
#

generate "vietnamese" \
  "vi_VN" \
  "GPL-2.0" \
  "LICENSES-en.txt" \
  "dictionaries/vi_VN.dic" \
  "dictionaries/vi_VN.aff" \
  "UTF-8"
