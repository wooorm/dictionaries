#!/bin/sh
ARCHIVES="archive"
SOURCES="source"
DICTIONARIES="dictionaries"

mkdir -p "$ARCHIVES"
mkdir -p "$SOURCES"
mkdir -p "$DICTIONARIES"

#####################################################################
# METHODS ###########################################################
#####################################################################

# ANSI colours.
function bold {
  printf "\033[1m%s\033[22m" "$1"
}

function green {
  printf "\033[32m%s\033[0m" "$1"
}

function red {
  printf "\033[31m%s\033[0m" "$1"
}

function yellow {
  printf "\033[33m%s\033[0m" "$1"
}

# Unpack an archive.
#
# @param $1 - Name of archive.
# @param $2 - Page of source.
# @param $3 - Path to archive.
unpack() {
  sourcePath="$SOURCES/$1"

  if [ ! -e "$sourcePath" ]; then
    filename=$(basename "$3")
    extension="${filename#*.}"

    echo "$3, $extension"

    if [ "$extension" = "tar.bz2" ]; then
      mkdir -p "$sourcePath"
      tar xvjf "$3" -C "$sourcePath" --strip-components=1
    elif [ "$extension" = "tar.gz" ]; then
      mkdir -p "$sourcePath"
      tar xzf "$3" -C "$sourcePath" --strip-components=1
    else
      unzip "$3" -d "$sourcePath"
    fi

    echo "$2" > "$sourcePath/SOURCE"
  fi
}

# Crawl and unpack an archive.
#
# @param $1 - Name of archive
# @param $2 - Page of source
# @param $3 - URL to archive
crawl() {
  printf "  $1"

  filename=$(basename "$3")

  if [ "$filename" = "download" ]; then
    filename=$(basename "$(dirname "$3")")
  fi

  extension="${filename#*.}"
  archivePath="$ARCHIVES/$1.zip"

  if [ "$extension" = "tar.bz2" ]; then
    archivePath="$ARCHIVES/$1.tar.bz2"
  fi
  # Normal GZipped tar, a hack for hebrew, and a hack for hungarian.
  if [ "$extension" = "tar.gz" ] || [ "$extension" = "4.tar.gz" ] || [ "$extension" = "6.1.tar.gz" ]; then
    archivePath="$ARCHIVES/$1.tar.gz"
  fi

  if [ ! -e "$archivePath" ]; then
    wget "$3" -O "$archivePath"
  fi

  unpack "$1" "$2" "$archivePath"
  printf " $(green "✓")\n"
}

# Generate a package from a crawled directory (at $1) and
# the given settings.
#
# @param $1 - Language / region code
# @param $2 - Name of source
# @param $3 - Path to `.dic` file
# @param $4 - Encoding of `.dic` file
# @param $5 - Path to `.aff` file
# @param $6 - Encoding of `.aff` file
# @param $7 - SPDX license
# @param $8 - Path to license file (`-` when not applicable)
# @param $9 - Encoding of license file (`-` when not applicable)
generate() {
  echo "  $(bold "$1") ($2)"
  SOURCE="$SOURCES/$2"
  dictionary="$DICTIONARIES/$1"

  mkdir -p "$dictionary"

  cp "$SOURCE/SOURCE" "$dictionary/SOURCE"

  (
    iconv -f "$4" -t "UTF-8" | # Encoding
    awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1' | # BOM
    sed 's/[ \t]*$//' | # Trailing white-space
    tr -d '\r' # Newlines
  ) < "$SOURCE/$3" > "$dictionary/index.dic"
  printf "   $(green "✓") index.dic (from $4)\n"

  (
    iconv -f "$6" -t "UTF-8" | # Encoding
    sed "s/SET .*/SET UTF-8/" | # Encoding Pragma
    awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1' | # BOM
    sed 's/[ \t]*$//' | # Trailing white-space
    tr -d '\r' # Newlines
  ) < "$SOURCE/$5" > "$dictionary/index.aff"
  printf "   $(green "✓") index.aff (from $6)\n"

  echo "$7" > "$dictionary/SPDX"

  if [ "$8" = "" ]; then
    printf "     No $(yellow "LICENSE") file\n"
  elif [ -e "$SOURCE/$8" ]; then
    (
      iconv -f "$9" -t "UTF-8" | # Encoding
      awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1' | # BOM
      sed 's/[ \t]*$//' | # Trailing white-space
      tr -d '\r' # Newlines
    ) < "$SOURCE/$8" > "$dictionary/LICENSE"
    printf "   $(green "✓") LICENSE (from $9)\n"
  else
    printf "   $(red "𐄂 Could not find LICENSE file")\n"
  fi
}

#####################################################################
# ARCHIVES ##########################################################
#####################################################################

printf "$(bold "Crawling")...\n"

# List of archives to crawl.
crawl "armenian-eastern" \
  "https://sites.google.com/site/araktransfer/home/spell-checkers" \
  "https://sites.google.com/site/araktransfer/home/spell-checkers/hy_AM_e_1940_dict-1.1.oxt"
crawl "armenian-western" \
  "https://sites.google.com/site/araktransfer/home/spell-checkers" \
  "https://sites.google.com/site/araktransfer/home/spell-checkers/hy_AM_western-1.0.oxt"
crawl "breton" \
  "http://drouizig.org/index.php/br/binviou-br/difazier-hunspell" \
  "http://drouizig.org/images/stories/difazier/hunspell/pakadaou/difazier-an-drouizig-0-14.zip"
crawl "bulgarian" \
  "http://extensions.openoffice.org/en/project/bulgarian-dictionaries-blgarski-rechnici" \
  "http://sourceforge.net/projects/aoo-extensions/files/744/8/dictionaries-bg.oxt/download"
crawl "catalan" \
  "https://github.com/Softcatala/catalan-dict-tools" \
  "https://github.com/Softcatala/catalan-dict-tools/releases/download/v3.0.2/ca.3.0.2-hunspell.zip"
crawl "catalan-valencian" \
  "https://github.com/Softcatala/catalan-dict-tools" \
  "https://github.com/Softcatala/catalan-dict-tools/releases/download/v3.0.2/ca-valencia.3.0.2-hunspell.zip"
crawl "croatian" \
  "http://cvs.linux.hr/spell/" \
  "http://cvs.linux.hr/spell/myspell/hr_HR.zip"
crawl "czech" \
  "http://extensions.openoffice.org/en/project/czech-dictionary-pack-ceske-slovniky-cs-cz" \
  "http://sourceforge.net/projects/aoo-extensions/files/1078/0/dict-cs-2.0.oxt/download"
crawl "danish" \
  "http://www.stavekontrolden.dk" \
  "http://www.stavekontrolden.dk/main/top/extension/dict-da-current.oxt"
crawl "dutch" \
  "https://github.com/OpenTaal/dutch" \
  "https://github.com/OpenTaal/dutch/archive/master.zip"
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
crawl "esperanto" \
  "http://www.esperantilo.org/index_en.html" \
  "http://www.esperantilo.org/evortaro.zip"
crawl "faroese" \
  "http://www.stava.fo" \
  "http://www.stava.fo/download/hunspell.zip"
crawl "french" \
  "https://www.dicollecte.org" \
  "http://www.dicollecte.org/grammalecte/oxt/Grammalecte-fr-v0.5.18.oxt"
crawl "frisian" \
  "https://taalweb.frl/downloads" \
  "https://www.fryske-akademy.nl/spell/oxt/fy_NL-20160722.oxt"
crawl "friulian" \
  "http://digilander.libero.it/paganf/coretors/dizionaris.html" \
  "http://digilander.libero.it/paganf/coretors/myspell-fur-12092005.zip"
crawl "gaelic" \
  "https://github.com/kscanne/hunspell-gd" \
  "https://github.com/kscanne/hunspell-gd/archive/master.zip"
crawl "galician" \
  "http://extensions.openoffice.org/en/project/corrector-ortografico-hunspell-para-galego" \
  "http://sourceforge.net/projects/aoo-extensions/files/5660/1/hunspell-gl-13.10.oxt/download"
crawl "german" \
  "https://www.j3e.de/ispell/igerman98/index_en.html" \
  "https://www.j3e.de/ispell/igerman98/dict/igerman98-20161207.tar.bz2"
crawl "greek" \
  "http://www.elspell.gr" \
  "https://github.com/stevestavropoulos/elspell/archive/master.zip"
crawl "greek-polyton" \
  "https://thepolytonicproject.gr/spell" \
  "https://sourceforge.net/projects/greekpolytonicsp/files/greek_polytonic_2.0.7.oxt/download"
crawl "hebrew" \
  "http://hspell.ivrix.org.il" \
  "http://hspell.ivrix.org.il/hspell-1.4.tar.gz"
crawl "hungarian" \
  "http://magyarispell.sourceforge.net" \
  "https://sourceforge.net/projects/magyarispell/files/Magyar%20Ispell/1.6.1/hu_HU-1.6.1.tar.gz/download"
crawl "interlingua" \
  "https://addons.mozilla.org/en-us/firefox/addon/dict-ia/" \
  "https://addons.mozilla.org/firefox/downloads/latest/dict-ia/addon-514646-latest.xpi"
crawl "interlingue" \
  "https://github.com/Carmina16/hunspell-ie" \
  "https://github.com/Carmina16/hunspell-ie/archive/master.zip"
crawl "irish" \
  "http://borel.slu.edu/ispell/index-en.html" \
  "https://github.com/kscanne/gaelspell/archive/master.zip"
crawl "italian" \
  "http://www.plio.it" \
  "https://sourceforge.net/projects/aoo-extensions/files/1204/14/dict-it.oxt/download"
crawl "kinyarwanda" \
  "https://github.com/kscanne/hunspell-rw" \
  "https://github.com/kscanne/hunspell-rw/archive/master.zip"
crawl "korean" \
  "https://github.com/spellcheck-ko/hunspell-dict-ko" \
  "https://github.com/spellcheck-ko/hunspell-dict-ko/releases/download/0.6.2/ko-aff-dic-0.6.2.zip"
crawl "latgalian" \
  "http://dict.dv.lv/home.php?prj=la" \
  "http://dict.dv.lv/download/ltg_LV-0.1.5.oxt"
crawl "latin" \
  "https://extensions.openoffice.org/project/dict-la" \
  "https://sourceforge.net/projects/aoo-extensions/files/1141/3/dict-la_2013-03-31.oxt/download"
crawl "libreoffice" \
  "https://github.com/LibreOffice/dictionaries" \
  "https://github.com/LibreOffice/dictionaries/archive/master.zip"
crawl "luxembourgish" \
  "https://github.com/spellchecker-lu/dictionary-lb-lu" \
  "https://github.com/spellchecker-lu/dictionary-lb-lu/archive/master.zip"
crawl "mongolian" \
  "http://extensions.openoffice.org/en/project/mongol-helniy-ugiyn-aldaa-shalgagch-ueer-taslagch-mongolian-spelling-and-hyphenation" \
  "http://sourceforge.net/projects/aoo-extensions/files/3204/2/dict-mn.oxt/download"
crawl "norwegian" \
  "http://extensions.openoffice.org/en/project/norwegian-dictionaries-spell-checker-thesaurus-and-hyphenation" \
  "http://sourceforge.net/projects/aoo-extensions/files/1216/6/dictionary-no-no-2.1.oxt/download"
crawl "polish" \
  "http://extensions.openoffice.org/en/project/polish-dictionary-pack" \
  "http://sourceforge.net/projects/aoo-extensions/files/806/4/pl-dict.oxt/download"
crawl "portuguese" \
  "http://extensions.openoffice.org/en/project/european-portuguese-dictionaries" \
  "http://sourceforge.net/projects/aoo-extensions/files/1196/35/oo3x-pt-pt-15.7.4.1.oxt/download"
crawl "portuguese-br" \
  "http://extensions.openoffice.org/en/project/vero-brazilian-portuguese-spellchecking-dictionary-hyphenator" \
  "http://sourceforge.net/projects/aoo-extensions/files/1375/8/vero_pt_br_v208aoc.oxt/download"
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

printf "$(bold "Crawled")!\n\n"

#####################################################################
# BUILD #############################################################
#####################################################################

printf "$(bold "Making")...\n"

echo "  basque"
mkdir -p "$SOURCES/basque"
echo "http://xuxen.eus/eu/bertsioak" > "$SOURCES/basque/SOURCE"
if [ ! -e "$SOURCES/basque/eu.aff" ]; then
  wget "http://xuxen.eus/static/hunspell/eu_ES.aff" -O "$SOURCES/basque/eu.aff"
fi
if [ ! -e "$SOURCES/basque/eu.dic" ]; then
  wget "http://xuxen.eus/static/hunspell/eu_ES.dic" -O "$SOURCES/basque/eu.dic"
fi

echo "  estonian"
mkdir -p "$SOURCES/estonian"
echo "http://www.meso.ee/~jjpp/speller" > "$SOURCES/estonian/SOURCE"
if [ ! -e "$SOURCES/estonian/et.aff" ]; then
  wget "http://www.meso.ee/~jjpp/speller/et_EE.aff" -O "$SOURCES/estonian/et.aff"
fi
if [ ! -e "$SOURCES/estonian/et.dic" ]; then
  wget "http://www.meso.ee/~jjpp/speller/et_EE.dic" -O "$SOURCES/estonian/et.dic"
fi

echo "  gaelic"
cd "$SOURCES/gaelic/hunspell-gd-master"
make gd_GB.dic gd_GB.aff
cd ../../..

echo "  german"
cd "$SOURCES/german"
make hunspell-all
cd ../..

echo "  greek"
cd "$SOURCES/greek/elspell-master"
make
cd ../../..

echo "  irish"
cd "$SOURCES/irish/gaelspell-master"
make ga_IE.dic ga_IE.aff
cd ../../..

echo "  kinyarwanda"
cd "$SOURCES/kinyarwanda/hunspell-rw-master"
make
cd ../../..

echo "  hebrew"
cd "$SOURCES/hebrew"
if [ ! -e "Makefile" ]; then
  ./configure
fi
PERL5LIB="$PERL5LIB:." make hunspell
cd ../..

printf "$(bold "Made")!\n\n"

#####################################################################
# DICTIONARIES ######################################################
#####################################################################

printf "$(bold "Generating")...\n"

generate "bg" "bulgarian" \
  "spell/bg_BG.dic" "CP1251" \
  "spell/bg_BG.aff" "CP1251" \
  "LGPL-2.1" "README.txt" "UTF-8"
generate "br" "breton" \
  "br_FR.dic" "UTF-8" \
  "br_FR.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "README.txt" "UTF-8"
generate "ca" "catalan" \
  "catalan.dic" "UTF-8" \
  "catalan.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1)" "LICENSE" "UTF-8"
generate "ca-valencia" "catalan-valencian" \
  "catalan-valencia.dic" "UTF-8" \
  "catalan-valencia.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1)" "LICENSE" "UTF-8"
generate "cs" "czech" \
  "cs_CZ.dic" "ISO8859-2" \
  "cs_CZ.aff" "ISO8859-2" \
  "GPL-2.0" "README_en.txt" "UTF-8"
generate "da" "danish" \
  "da_DK.dic" "UTF-8" \
  "da_DK.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "README_da_DK.txt" "UTF-8"
generate "de" "german" \
  "hunspell/de_DE.dic" "ISO8859-1" \
  "hunspell/de_DE.aff" "ISO8859-1" \
  "(GPL-2.0 OR GPL-3.0)" "hunspell/Copyright" "UTF-8" \
generate "de-AT" "german" \
  "hunspell/de_AT.dic" "ISO8859-1" \
  "hunspell/de_AT.aff" "ISO8859-1" \
  "(GPL-2.0 OR GPL-3.0)" "hunspell/Copyright" "UTF-8" \
generate "de-CH" "german" \
  "hunspell/de_CH.dic" "ISO8859-1" \
  "hunspell/de_CH.aff" "ISO8859-1" \
  "(GPL-2.0 OR GPL-3.0)" "hunspell/Copyright" "UTF-8"
generate "el" "greek" \
  "elspell-master/myspell/el_GR.dic" "UTF-8" \
  "elspell-master/myspell/el_GR.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "elspell-master/myspell/README_el_GR.txt" "UTF-8"
generate "el-polyton" "greek-polyton" \
  "el_GR.dic" "UTF-8" \
  "el_GR.aff" "UTF-8" \
  "GPL-3.0" "README_el_GR.txt" "UTF-8"
# Note that “the Hunspell English Dictionaries” are very vaguely licensed.
# Read more in the license file. Note that the SPDX “(MIT AND BSD)”
# comes from aspell’s description as “BSD/MIT-like”.
# See: http://wordlist.aspell.net/other-dicts/#official
generate "en-AU" "english-australian" \
  "en_AU.dic" "UTF-8" \
  "en_AU.aff" "UTF-8" \
  "(MIT AND BSD)" "README_en_AU.txt" "UTF-8"
generate "en-CA" "english-canadian" \
  "en_CA.dic" "UTF-8" \
  "en_CA.aff" "UTF-8" \
  "(MIT AND BSD)" "README_en_CA.txt" "UTF-8"
generate "en-GB" "english-gb" \
  "en_GB-ise.dic" "UTF-8" \
  "en_GB-ise.aff" "UTF-8" \
  "(MIT AND BSD)" "README_en_GB-ise.txt" "UTF-8"
generate "en-US" "english-american" \
  "en_US.dic" "UTF-8" \
  "en_US.aff" "UTF-8" \
  "(MIT AND BSD)" "README_en_US.txt" "UTF-8"
generate "en-ZA" "english" \
  "en_ZA.dic" "UTF-8" \
  "en_ZA.aff" "UTF-8" \
  "LGPL-2.1" "README_en_ZA.txt" "UTF-8"
generate "eo" "esperanto" \
  "eo_ilo.dic" "UTF-8" \
  "eo_ilo.aff" "UTF-8" \
  "GPL-2.0" "LICENSE.txt" "UTF-8"
generate "es" "spanish" \
  "es_ES.dic" "ISO8859-1" \
  "es_ES.aff" "ISO8859-1" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "et" "estonian" \
  "et.dic" "ISO8859-15" \
  "et.aff" "ISO8859-15" \
  "LGPL-2.1"
generate "eu" "basque" \
  "eu.dic" "UTF-8" \
  "eu.aff" "UTF-8" \
  "GPL-2.0"
generate "fo" "faroese" \
  "fo_FO.dic" "ISO8859-1" \
  "fo_FO.aff" "ISO8859-1" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "LICENSE_en_US.txt" "UTF-8"
generate "fr" "french" \
  "dictionaries/fr-classique.dic" "UTF-8" \
  "dictionaries/fr-classique.aff" "UTF-8" \
  "MPL-2.0" "dictionaries/README_dict_fr.txt" "UTF-8"
generate "fur" "friulian" \
  "myspell-fur-12092005/fur_IT.dic" "ISO8859-1" \
  "myspell-fur-12092005/fur_IT.aff" "ISO8859-1" \
  "GPL-2.0" "myspell-fur-12092005/COPYING.txt" "ISO8859-1"
generate "fy" "frisian" \
  "fy_NL.dic" "CP1252" \
  "fy_NL.aff" "CP1252" \
  "GPL-3.0" "README" "UTF-8"
generate "ga" "irish" \
  "gaelspell-master/ga_IE.dic" "UTF-8" \
  "gaelspell-master/ga_IE.aff" "UTF-8" \
  "GPL-2.0" "gaelspell-master/LICENSES-en.txt" "UTF-8"
generate "gd" "gaelic" \
  "hunspell-gd-master/gd_GB.dic" "UTF-8" \
  "hunspell-gd-master/gd_GB.aff" "UTF-8" \
  "GPL-3.0" "hunspell-gd-master/README_gd_GB.txt" "UTF-8"
generate "gl" "galician" \
  "gl_ES.dic" "UTF-8" \
  "gl_ES.aff" "UTF-8" \
  "GPL-3.0" "license.txt" "UTF-8"
generate "he" "hebrew" \
  "he.dic" "UTF-8" \
  "he.aff" "UTF-8" \
  "AGPL-3.0" "LICENSE" "UTF-8"
generate "hr" "croatian" \
  "hr_HR.dic" "ISO8859-2" \
  "hr_HR.aff" "ISO8859-2" \
  "(LGPL-2.1 OR SISSL)" "README_hr_HR.txt" "ISO8859-2"
generate "hu" "hungarian" \
  "hu_HU.dic" "ISO8859-2" \
  "hu_HU.aff" "ISO8859-2" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "README_hu_HU.txt" "UTF-8"
generate "hy-arevela" "armenian-eastern" \
  "hy_am_e_1940.dic" "UTF-8" \
  "hy_am_e_1940.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "COPYING" "UTF-8"
generate "hy-arevmda" "armenian-western" \
  "hy_AM_western.dic" "UTF-8" \
  "hy_AM_western.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "COPYING" "UTF-8"
generate "ia" "interlingua" \
  "dictionaries/ia.dic" "UTF-8" \
  "dictionaries/ia.aff" "UTF-8" \
  "GPL-3.0" "dictionaries/README_dict-ia.txt" "UTF-8"
generate "ie" "interlingue" \
  "hunspell-ie-master/ie.dic" "UTF-8" \
  "hunspell-ie-master/ie.aff" "UTF-8" \
  "Apache-2.0" "hunspell-ie-master/LICENSE" "UTF-8"
generate "is" "libreoffice" \
  "dictionaries-master/is/is.dic" "UTF-8" \
  "dictionaries-master/is/is.aff" "UTF-8" \
  "CC-BY-SA-3.0" "dictionaries-master/is/license.txt" "UTF-8"
generate "it" "italian" \
  "dictionaries/it_IT.dic" "UTF-8" \
  "dictionaries/it_IT.aff" "UTF-8" \
  "GPL-3.0" "dictionaries/README.txt" "UTF-8"
generate "ko" "korean" \
  "ko-aff-dic-0.6.2/ko.dic" "UTF-8" \
  "ko-aff-dic-0.6.2/ko.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "ko-aff-dic-0.6.2/LICENSE" "UTF-8"
generate "la" "latin" \
  "la/universal/la.dic" "UTF-8" \
  "la/universal/la.aff" "UTF-8" \
  "GPL-2.0" "la/README_la.txt" "CP1252"
generate "lb" "luxembourgish" \
  "dictionary-lb-lu-master/lb_LU.dic" "UTF-8" \
  "dictionary-lb-lu-master/lb_LU.aff" "UTF-8" \
  "EUPL-1.1" "dictionary-lb-lu-master/LICENSE.txt" "UTF-8"
generate "ltg" "latgalian" \
  "ltg_LV.dic" "UTF-8" \
  "ltg_LV.aff" "UTF-8" \
  "LGPL-2.1" "README_ltg_LV.txt" "UTF-8"
generate "mn" "mongolian" \
  "mn_MN.dic" "UTF-8" \
  "mn_MN.aff" "UTF-8" \
  "GPL-2.0" "README_mn_MN.txt" "UTF-8"
generate "nb" "norwegian" \
  "DICT/nb_NO.dic" "ISO8859-1" \
  "DICT/nb_NO.aff" "ISO8859-1" \
  "GPL-2.0" "COPYING" "ISO8859-1"
generate "nl" "dutch" \
  "dutch-master/result/hunspell-nl/usr/share/hunspell/nl.dic" "UTF-8" \
  "dutch-master/result/hunspell-nl/usr/share/hunspell/nl.aff" "UTF-8" \
  "(BSD-3-Clause OR CC-BY-3.0)" "dutch-master/LICENSE" "UTF-8"
generate "nn" "norwegian" \
  "DICT/nn_NO.dic" "ISO8859-1" \
  "DICT/nn_NO.aff" "ISO8859-1" \
  "GPL-2.0" "COPYING" "ISO8859-1"
generate "pl" "polish" \
  "pl_PL.dic" "ISO8859-2" \
  "pl_PL.aff" "ISO8859-2" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-2.0)" "README_en.txt" "UTF-8"
generate "pt" "portuguese" \
  "dictionaries/pt_PT.dic" "UTF-8" \
  "dictionaries/pt_PT.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "dictionaries/README_pt_PT.txt" "ISO8859-1"
generate "pt-BR" "portuguese-br" \
  "pt_BR.dic" "ISO8859-1" \
  "pt_BR.aff" "ISO8859-1" \
  "LGPL-2.1" "README_en.TXT" "UTF-8"
generate "ro" "romanian" \
  "ro_RO.dic" "UTF-8" \
  "ro_RO.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "README_EN.txt" "UTF-8"
generate "ru" "russian" \
  "ru_RU.dic" "KOI8-R" \
  "ru_RU.aff" "KOI8-R" \
  "BSD-2-Clause" "LICENSE" "UTF-8"
generate "rw" "kinyarwanda" \
  "hunspell-rw-master/rw_RW.dic" "ISO8859-1" \
  "hunspell-rw-master/rw_RW.aff" "ISO8859-1" \
  "GPL-3.0" "hunspell-rw-master/LICENSE" "UTF-8" \
generate "sk" "slovak" \
  "sk_SK/sk_SK.dic" "UTF-8" \
  "sk_SK/sk_SK.aff" "UTF-8" \
  "GPL-2.0" "LICENSE.txt" "UTF-8"
generate "sl" "slovenian" \
  "sl_SI.dic" "ISO8859-2" \
  "sl_SI.aff" "ISO8859-2" \
  "(GPL-3.0 OR LGPL-2.1)" "README_sl_SI.txt" "UTF-8"
generate "sr" "serbian" \
  "sr.dic" "UTF-8" \
  "sr.aff" "UTF-8" \
  "LGPL-3.0" "registration/license_en-US.txt" "UTF-8"
generate "sr-Latn" "serbian" \
  "sr-Latn.dic" "UTF-8" \
  "sr-Latn.aff" "UTF-8" \
  "LGPL-3.0" "registration/license_en-US.txt" "UTF-8"
generate "sv" "swedish" \
  "sv_SE.dic" "UTF-8" \
  "sv_SE.aff" "UTF-8" \
  "LGPL-3.0" "LICENSE_en_US.txt" "UTF-8"
generate "tr" "turkish" \
  "dictionaries/tr-TR.dic" "UTF-8" \
  "dictionaries/tr-TR.aff" "UTF-8" \
  "MIT"
generate "uk" "ukrainian" \
  "uk_UA/uk_UA.dic" "UTF-8" \
  "uk_UA/uk_UA.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "uk_UA/README_uk_UA.txt" "UTF-8"
generate "vi" "vietnamese" \
  "dictionaries/vi_VN.dic" "UTF-8" \
  "dictionaries/vi_VN.aff" "UTF-8" \
  "GPL-2.0" "LICENSES-en.txt" "UTF-8"

printf "$(bold "Generated")!\n\n"

#####################################################################
# FIX ###############################################################
#####################################################################

printf "$(bold "Fixing")...\n"

printf "  hu"
# Hack around the broken Hungarian affix file.
if [ "$(head -n 1 "$DICTIONARIES/hu/index.aff")" = "AF 1263" ]; then
  tail -n 23734 "$DICTIONARIES/hu/index.aff" > "$DICTIONARIES/hu/index-fixed.aff"
  mv "$DICTIONARIES/hu/index-fixed.aff" "$DICTIONARIES/hu/index.aff"
fi
printf " $(green "✓")\n"

printf "$(bold "Fixed")!\n\n"
