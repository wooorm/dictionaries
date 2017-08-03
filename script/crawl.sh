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
#
unpack() {
  ARCHIVE_PATH="$ARCHIVES/$1.zip"
  SOURCE_PATH="$SOURCES/$1"

  if [ ! -e "$SOURCE_PATH" ]; then
    unzip "$ARCHIVES/$1.zip" -d "$SOURCE_PATH"
  fi

  echo "$2" > "$SOURCE_PATH/SOURCE"
}

#
# Crawl and unpack an archive.
#
# @param $1 - Name of archive;
# @param $2 - Page of source.
# @param $3 - URL to archive.
#
crawl() {
  ARCHIVE_PATH="$ARCHIVES/$1.zip"

  if [ ! -e "$ARCHIVE_PATH" ]; then
    wget "$3" -O "$ARCHIVE_PATH"
  fi

  unpack "$1" "$2"
}

#
# Copy a local archive and unpack it.
#
# @param $1 - Name of archive.
# @param $2 - Page of source.
#
uncrawl() {
  ARCHIVE_PATH="$ARCHIVES/$1.zip"

  if [ ! -e "$ARCHIVE_PATH" ]; then
    cp "$UNCRAWLABLES/$1.zip" "$ARCHIVE_PATH"
  fi

  unpack "$1" "$2"

  echo "Warning: Loading local $1"
}

#
# Generate a package from a crawled directory (at $1) and
# the given settings.
#
# @param $1 - Name of source;
# @param $2 - Language / region code;
# @param $3 - SPDX license;
# @param $4 - Path to lincese file. Should be `-` when not
#   applicable;
# @param $5 - Path to `.aff` file;
# @param $6 - Path to `.dic` file;
# @param $7 - Encoding of `.aff` and `.dic` file.
#
generate() {
  SOURCE="$SOURCES/$1"
  dictionary="$DICTIONARIES/$2"

  mkdir -p "$dictionary"

  cp "$SOURCE/SOURCE" "$dictionary/SOURCE"

  echo "$3" > "$dictionary/SPDX"

  if [ -e "$SOURCE/$4" ]; then
    tr -d '\r' < "$SOURCE/$4" > "$dictionary/LICENSE"
  else
    echo "Warning: Missing LICENSE file for $2"
  fi

  (iconv -f "$7" -t "UTF-8" | sed "s/SET $8/SET UTF-8/" | tr -d '\r') < "$SOURCE/$5" > "$dictionary/index.dic"
  (iconv -f "$7" -t "UTF-8" | sed "s/SET $7/SET UTF-8/" | tr -d '\r') < "$SOURCE/$6" > "$dictionary/index.aff"
}

#####################################################################
# ARCHIVES ##########################################################
#####################################################################

#
# List of archives to crawl.
#

crawl "austrian" \
  "http://extensions.openoffice.org/en/project/german-de-frami-dictionaries" \
  "http://sourceforge.net/projects/aoo-extensions/files/1697/10/dict-de_at-frami_2013-12-06.oxt/download"
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
  "http://extensions.openoffice.org/en/project/danish-spellcheck-and-hyphenation-dictionaries" \
  "http://sourceforge.net/projects/aoo-extensions/files/1429/6/dict-da-current.oxt/download"
crawl "dutch" \
  "http://extensions.openoffice.org/en/project/dutch-spelling-and-hyphenation-dictionary" \
  "http://sourceforge.net/projects/aoo-extensions/files/1456/6/nl-dict-v2.00g.oxt/download"
crawl "english" \
  "http://extensions.openoffice.org/en/project/english-dictionaries-apache-openoffice" \
  "http://sourceforge.net/projects/aoo-extensions/files/17102/19/dict-en.oxt/download"
crawl "french" \
  "https://www.dicollecte.org" \
  "http://www.dicollecte.org/grammalecte/oxt/Grammalecte-fr-v0.5.18.oxt"
crawl "galician" \
  "http://extensions.openoffice.org/en/project/corrector-ortografico-hunspell-para-galego" \
  "http://sourceforge.net/projects/aoo-extensions/files/5660/1/hunspell-gl-13.10.oxt/download"
crawl "german" \
  "http://extensions.openoffice.org/en/project/german-de-de-igerman98-dictionaries" \
  "http://sourceforge.net/projects/aoo-extensions/files/1050/4/dict-de_de-igerman98_2011-06-21.oxt/download"
crawl "greek" \
  "http://extensions.openoffice.org/en/project/hellenic-greek-dictionary-spell-check-and-hyphenation" \
  "http://sourceforge.net/projects/aoo-extensions/files/1411/2/el_gr_v110.oxt/download"
# Disabled due to unknown encoding.
# crawl "hungarian" \
#    "http://extensions.openoffice.org/en/project/hungarian-dictionary-pack" \
#    "http://sourceforge.net/projects/aoo-extensions/files/1283/9/dict-hu.oxt/download"
crawl "italian" \
  "http://extensions.openoffice.org/en/project/italian-dictionary-thesaurus-hyphenation-patterns" \
  "http://sourceforge.net/projects/aoo-extensions/files/1204/13/dict-it.oxt/download"
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
crawl "switzerland" \
  "http://extensions.openoffice.org/en/project/german-de-ch-igerman98-dictionaries" \
  "http://sourceforge.net/projects/aoo-extensions/files/1712/3/dict-de_ch-igerman98_2011-06-21.oxt/download"
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
# DICTIONARIES ######################################################
#####################################################################

#
# German (Austrian).
#

generate "austrian" \
  "de_AT" \
  "(GPL-2.0 OR GPL-3.0)" \
  "hyph_de_AT/README_hyph_de_AT.txt" \
  "de_AT_frami/de_AT_frami.dic" \
  "de_AT_frami/de_AT_frami.aff" \
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
  "(GPL-2.0 OR LGPL-2.0 OR MPL-1.1)" \
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
# English (Australian, Canadian, British, American, South African)
#

generate "english" \
  "en_AU" \
  "LGPL-2.0" \
  "README_en_AU.txt" \
  "en_AU.dic" \
  "en_AU.aff" \
  "UTF-8"

generate "english" \
  "en_GB" \
  "LGPL-2.0" \
  "README_en_GB.txt" \
  "en_GB.dic" \
  "en_GB.aff" \
  "UTF-8"

generate "english" \
  "en_ZA" \
  "LGPL-2.1" \
  "README_en_ZA.txt" \
  "en_ZA.dic" \
  "en_ZA.aff" \
  "UTF-8"

#
# Note that Canadian- and American English (“the Hunspell English
# Dictionaries”) are very vaguely licensed.
# Read more in the license file. Note that the SPDX “(MIT AND BSD)”
# comes from aspell’s description as “BSD/MIT-like”.
#
# See: http://wordlist.aspell.net/other-dicts/#official
#

generate "english" \
  "en_CA" \
  "(MIT AND BSD)" \
  "README_en_CA.txt" \
  "en_CA.dic" \
  "en_CA.aff" \
  "UTF-8"

generate "english" \
  "en_US" \
  "(MIT AND BSD)" \
  "README_en_US.txt" \
  "en_US.dic" \
  "en_US.aff" \
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
  "de_DE_igerman98/Copyright" \
  "de_DE_igerman98/de_DE_igerman98.dic" \
  "de_DE_igerman98/de_DE_igerman98.aff" \
  "ISO8859-1"

#
# Greek.
#

generate "greek" \
  "el_GR" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" \
  "README_el_GR.txt" \
  "el_GR.dic" \
  "el_GR.aff" \
  "ISO8859-7"

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
  "mn_MN.aff" \
  "mn_MN.dic" \
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

generate "switzerland" \
  "de_CH" \
  "(GPL-2.0 OR GPL-3.0)" \
  "de_CH_igerman98/Copyright" \
  "de_CH_igerman98/de_CH_igerman98.dic" \
  "de_CH_igerman98/de_CH_igerman98.aff" \
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
