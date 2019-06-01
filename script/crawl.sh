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

    if [ "$extension" = "tar.bz2" ]; then
      mkdir -p "$sourcePath"
      tar xvjf "$3" -C "$sourcePath" --strip-components=1
    elif [ "$extension" = "tar.gz" ]; then
      mkdir -p "$sourcePath"
      tar xzf "$3" -C "$sourcePath" --strip-components=1
    else
      unzip "$3" -d "$sourcePath"
    fi

    echo "$2" > "$sourcePath/.source"
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
  # Normal GZipped tar, and a hack for hebrew.
  if [ "$extension" = "tar.gz" ] || [ "$extension" = "4.tar.gz" ]; then
    archivePath="$ARCHIVES/$1.tar.gz"
  fi

  if [ ! -e "$archivePath" ]; then
    echo
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

  cp "$SOURCE/.source" "$dictionary/.source"

  if [ -e "$SOURCE/$3" ]; then
    (
      iconv -f "$4" -t "UTF-8" | # Encoding
      awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1' | # BOM
      sed 's/[ 	]*$//' | # Trailing white-space
      tr -d '\r' # Newlines
    ) < "$SOURCE/$3" > "$dictionary/index.dic"
    printf "   $(green "✓") index.dic (from $4)\n"
  else
    printf "   $(red "𐄂 Could not find $3 file")\n"
  fi

  if [ -e "$SOURCE/$5" ]; then
    (
      iconv -f "$6" -t "UTF-8" | # Encoding
      sed "s/SET .*/SET UTF-8/" | # Encoding Pragma
      awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1' | # BOM
      sed 's/[ 	]*$//' | # Trailing white-space
      tr -d '\r' # Newlines
    ) < "$SOURCE/$5" > "$dictionary/index.aff"
    printf "   $(green "✓") index.aff (from $6)\n"
  else
    printf "   $(red "𐄂 Could not find $5 file")\n"
  fi

  echo "$7" > "$dictionary/.spdx"

  if [ "$8" = "" ]; then
    printf "     No $(yellow "license") file\n"
  elif [ -e "$SOURCE/$8" ]; then
    (
      iconv -f "$9" -t "UTF-8" | # Encoding
      awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1' | # BOM
      sed 's/[ 	]*$//' | # Trailing white-space
      tr -d '\r' # Newlines
    ) < "$SOURCE/$8" > "$dictionary/license"
    printf "   $(green "✓") license (from $9)\n"
  else
    printf "   $(red "𐄂 Could not find license file")\n"
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
crawl "basque" \
  "http://xuxen.eus/eu/home" \
  "http://xuxen.eus/static/hunspell/xuxen_5.1_hunspell.zip"
crawl "breton" \
  "http://drouizig.org/index.php/br/binviou-br/difazier-hunspell" \
  "http://drouizig.org/images/stories/difazier/hunspell/pakadaou/difazier-an-drouizig-0-14.zip"
crawl "bulgarian" \
  "http://bgoffice.sourceforge.net" \
  "https://iweb.dl.sourceforge.net/project/bgoffice/OpenOffice.org%20Full%20Pack/4.3/OOo-full-pack-bg-4.3.zip"
crawl "catalan" \
  "https://github.com/Softcatala/catalan-dict-tools" \
  "https://github.com/Softcatala/catalan-dict-tools/releases/download/v3.0.3/ca.3.0.3-hunspell.zip"
crawl "catalan-valencian" \
  "https://github.com/Softcatala/catalan-dict-tools" \
  "https://github.com/Softcatala/catalan-dict-tools/releases/download/v3.0.3/ca-valencia.3.0.3-hunspell.zip"
crawl "croatian" \
  "http://cvs.linux.hr/spell/" \
  "http://cvs.linux.hr/spell/myspell/hr_HR.zip"
crawl "czech" \
  "http://extensions.openoffice.org/en/project/czech-dictionary-pack-ceske-slovniky-cs-cz" \
  "https://iweb.dl.sourceforge.net/project/aoo-extensions/1078/0/dict-cs-2.0.oxt"
crawl "danish" \
  "http://www.stavekontrolden.dk" \
  "http://www.stavekontrolden.dk/main/top/extension/dict-da-current.oxt"
crawl "dutch" \
  "https://github.com/OpenTaal/dutch" \
  "https://github.com/OpenTaal/dutch/archive/master.zip"
crawl "english" \
  "http://extensions.openoffice.org/en/project/english-dictionaries-apache-openoffice" \
  "https://iweb.dl.sourceforge.net/project/aoo-extensions/17102/47/dict-en-20190501b.oxt"
crawl "english-gb" \
  "http://wordlist.aspell.net/dicts/" \
  "https://iweb.dl.sourceforge.net/project/wordlist/speller/2018.04.16/hunspell-en_GB-ise-2018.04.16.zip"
crawl "english-american" \
  "http://wordlist.aspell.net/dicts/" \
  "https://netix.dl.sourceforge.net/project/wordlist/speller/2018.04.16/hunspell-en_US-2018.04.16.zip"
crawl "english-canadian" \
  "http://wordlist.aspell.net/dicts/" \
  "https://iweb.dl.sourceforge.net/project/wordlist/speller/2018.04.16/hunspell-en_CA-2018.04.16.zip"
crawl "english-australian" \
  "http://wordlist.aspell.net/dicts/" \
  "https://datapacket.dl.sourceforge.net/project/wordlist/speller/2018.04.16/hunspell-en_AU-2018.04.16.zip"
crawl "esperanto" \
  "http://www.esperantilo.org/index_en.html" \
  "http://www.esperantilo.org/evortaro.zip"
# TODO: Stava is down.
# crawl "faroese" \
#   "http://www.stava.fo" \
#   "http://www.stava.fo/download/hunspell.zip"
crawl "french" \
  "https://grammalecte.net" \
  "http://www.dicollecte.org/download/fr/hunspell-french-dictionaries-v6.4.1.zip"
crawl "frisian" \
  "https://github.com/PanderMusubi/frisian" \
  "https://github.com/PanderMusubi/frisian/archive/master.zip"
crawl "friulian" \
  "http://digilander.libero.it/paganf/coretors/dizionaris.html" \
  "http://digilander.libero.it/paganf/coretors/myspell-fur-12092005.zip"
crawl "gaelic" \
  "https://github.com/kscanne/hunspell-gd" \
  "https://github.com/kscanne/hunspell-gd/archive/master.zip"
crawl "galician" \
  "http://extensions.openoffice.org/en/project/corrector-ortografico-hunspell-para-galego" \
  "https://iweb.dl.sourceforge.net/project/aoo-extensions/5660/1/hunspell-gl-13.10.oxt"
crawl "georgian" \
  "https://github.com/gamag/ka_GE.spell" \
  "https://github.com/gamag/ka_GE.spell/archive/master.zip"
crawl "german" \
  "https://www.j3e.de/ispell/igerman98/index_en.html" \
  "https://www.j3e.de/ispell/igerman98/dict/igerman98-20161207.tar.bz2"
crawl "greek" \
  "https://github.com/stevestavropoulos/elspell" \
  "https://github.com/stevestavropoulos/elspell/archive/master.zip"
crawl "greek-polyton" \
  "https://thepolytonicproject.gr/spell" \
  "https://iweb.dl.sourceforge.net/project/greekpolytonicsp/greek_polytonic_2.0.7.oxt"
crawl "hebrew" \
  "http://hspell.ivrix.org.il" \
  "http://hspell.ivrix.org.il/hspell-1.4.tar.gz"
# TODO: laszlonemeth/magyarispell#9
# crawl "hungarian" \
#   "https://github.com/laszlonemeth/magyarispell" \
#   "https://github.com/laszlonemeth/magyarispell/archive/master.zip"
crawl "interlingua" \
  "https://addons.mozilla.org/en-us/firefox/addon/dict-ia/" \
  "https://addons.mozilla.org/firefox/downloads/latest/dict-ia/addon-514646-latest.xpi"
crawl "interlingue" \
  "https://github.com/Carmina16/hunspell-ie" \
  "https://github.com/Carmina16/hunspell-ie/archive/master.zip"
# TODO: kscanne/gaelspell#2
# crawl "irish" \
#   "https://github.com/kscanne/gaelspell" \
#   "https://github.com/kscanne/gaelspell/archive/v5.0.zip"
crawl "italian" \
  "http://www.plio.it" \
  "https://iweb.dl.sourceforge.net/project/aoo-extensions/1204/14/dict-it.oxt"
crawl "kinyarwanda" \
  "https://github.com/kscanne/hunspell-rw" \
  "https://github.com/kscanne/hunspell-rw/archive/master.zip"
crawl "korean" \
  "https://github.com/spellcheck-ko/hunspell-dict-ko" \
  "https://github.com/spellcheck-ko/hunspell-dict-ko/releases/download/0.7.1/ko-aff-dic-0.7.1.zip"
crawl "latgalian" \
  "http://dict.dv.lv/home.php?prj=la" \
  "http://dict.dv.lv/download/ltg_LV-0.1.5.oxt"
crawl "latvian" \
  "http://dict.dv.lv/home.php?prj=lv" \
  "http://dict.dv.lv/download/lv_LV-1.3.0.oxt"
crawl "latin" \
  "https://extensions.openoffice.org/project/dict-la" \
  "https://iweb.dl.sourceforge.net/project/aoo-extensions/1141/3/dict-la_2013-03-31.oxt"
crawl "libreoffice" \
  "https://github.com/LibreOffice/dictionaries" \
  "https://github.com/LibreOffice/dictionaries/archive/master.zip"
crawl "lithuanian" \
  "https://launchpad.net/ispell-lt" \
  "https://launchpad.net/ispell-lt/main/1.3/+download/myspell-lt-1.3.zip"
crawl "low-german" \
  "https://github.com/tdf/dict_nds" \
  "https://github.com/tdf/dict_nds/archive/master.zip"
crawl "luxembourgish" \
  "https://github.com/spellchecker-lu/dictionary-lb-lu" \
  "https://github.com/spellchecker-lu/dictionary-lb-lu/archive/master.zip"
# crawl "macedonian" \
#   "https://github.com/dimztimz/hunspell-mk" \
#   "https://github.com/dimztimz/hunspell-mk/archive/master.zip"
crawl "mongolian" \
  "http://extensions.openoffice.org/en/project/mongol-helniy-ugiyn-aldaa-shalgagch-ueer-taslagch-mongolian-spelling-and-hyphenation" \
  "https://iweb.dl.sourceforge.net/project/aoo-extensions/3204/2/dict-mn.oxt"
crawl "nepali" \
  "http://ltk.org.np" \
  "http://ltk.org.np/downloads/ne_NP_dict.zip"
crawl "norwegian" \
  "http://no.speling.org" \
  "https://alioth-archive.debian.org/releases/spell-norwegian/spell-norwegian/spell-norwegian-latest.zip"
crawl "persian" \
  "https://github.com/b00f/lilak" \
  "https://github.com/b00f/lilak/releases/download/v3.2/fa-IR.zip"
crawl "polish" \
  "http://extensions.openoffice.org/en/project/polish-dictionary-pack" \
  "https://iweb.dl.sourceforge.net/project/aoo-extensions/806/4/pl-dict.oxt"
crawl "portuguese" \
  "http://natura.di.uminho.pt" \
  "http://natura.di.uminho.pt/download/sources/Dictionaries/hunspell/hunspell-pt_PT-20190329.tar.gz"
crawl "portuguese-br" \
  "http://extensions.openoffice.org/en/project/vero-brazilian-portuguese-spellchecking-dictionary-hyphenator" \
  "https://iweb.dl.sourceforge.net/project/aoo-extensions/1375/8/vero_pt_br_v208aoc.oxt"
crawl "romanian" \
  "http://extensions.openoffice.org/en/project/romanian-dictionary-pack-spell-checker-hyphenation-thesaurus" \
  "https://iweb.dl.sourceforge.net/project/aoo-extensions/1392/10/dict-ro.1.7.oxt"
crawl "russian" \
  "http://extensions.openoffice.org/en/project/russian-dictionary" \
  "https://iweb.dl.sourceforge.net/project/aoo-extensions/936/9/dict_ru_ru-0.6.oxt"
crawl "serbian" \
  "http://extensions.openoffice.org/en/project/serbian-cyrillic-and-latin-spelling-and-hyphenation" \
  "https://iweb.dl.sourceforge.net/project/aoo-extensions/1572/9/dict-sr.oxt"
crawl "slovak" \
  "http://extensions.openoffice.org/en/project/slovak-dictionary-package-slovenske-slovniky" \
  "https://iweb.dl.sourceforge.net/project/aoo-extensions/1143/11/dict-sk.oxt"
crawl "slovenian" \
  "http://extensions.openoffice.org/en/project/slovenian-dictionary-package-slovenski-paket-slovarjev" \
  "https://vorboss.dl.sourceforge.net/project/aoo-extensions/3280/10/pack-sl.oxt"
crawl "spanish" \
  "http://extensions.openoffice.org/en/project/spanish-espanol" \
  "https://datapacket.dl.sourceforge.net/project/aoo-extensions/2979/3/es_es.oxt"
crawl "swedish" \
  "http://extensions.openoffice.org/en/project/swedish-dictionaries-apache-openoffice" \
  "https://iweb.dl.sourceforge.net/project/aoo-extensions/5959/1/dict-sv.oxt"
crawl "turkish" \
  "http://extensions.openoffice.org/en/project/turkish-spellcheck-dictionary" \
  "https://iweb.dl.sourceforge.net/project/aoo-extensions/18079/0/oo-turkish-dict-v1.3.oxt"
crawl "turkmen" \
  "https://github.com/nazartm/turkmen-spell-check-dictionary" \
  "https://github.com/nazartm/turkmen-spell-check-dictionary/archive/master.zip"
crawl "ukrainian" \
  "https://github.com/brown-uk/dict_uk" \
  "https://github.com/brown-uk/dict_uk/releases/download/v4.4.2/hunspell-uk_UA_4.4.2.zip"
crawl "vietnamese" \
  "https://github.com/1ec5/hunspell-vi" \
  "https://github.com/1ec5/hunspell-vi/releases/download/v2.2.0/vi_spellchecker_OOo3.oxt"

printf "$(bold "Crawled")!\n\n"

#####################################################################
# BUILD #############################################################
#####################################################################

printf "$(bold "Making")...\n"

echo "  estonian"
mkdir -p "$SOURCES/estonian"
echo "http://www.meso.ee/~jjpp/speller" > "$SOURCES/estonian/.source"
if [ ! -e "$SOURCES/estonian/et.aff" ]; then
  wget "http://www.meso.ee/~jjpp/speller/et_EE.aff" -O "$SOURCES/estonian/et.aff"
fi
if [ ! -e "$SOURCES/estonian/et.dic" ]; then
  wget "http://www.meso.ee/~jjpp/speller/et_EE.dic" -O "$SOURCES/estonian/et.dic"
fi

echo "  gaelic"
cd "$SOURCES/gaelic/hunspell-gd-master" || exit
make gd_GB.dic gd_GB.aff
cd ../../.. || exit

echo "  german"
cd "$SOURCES/german" || exit
make hunspell-all
cd ../.. || exit

echo "  greek"
cd "$SOURCES/greek/elspell-master" || exit
make
cd ../../.. || exit

echo "  greek (polyton)"
cd "$SOURCES/greek-polyton" || exit
sed -i 's/REP έψ	εύσ/REP έψ εύσ/g' el_GR.aff
printf "   $(green "✓") fixed tab\n"
cd ../.. || exit

# TODO: kscanne/gaelspell#2
# echo "  irish"
# cd "$SOURCES/irish/gaelspell-5.0" || exit
# cpan -i Roman.pm
# make ga_IE.aff ga_IE.dic
# cd ../../.. || exit

echo "  kinyarwanda"
cd "$SOURCES/kinyarwanda/hunspell-rw-master" || exit
make
cd ../../.. || exit

echo "  hebrew"
cd "$SOURCES/hebrew" || exit
if [ ! -e "Makefile" ]; then
  ./configure
fi
PERL5LIB="$PERL5LIB:." make hunspell
cd ../.. || exit

# TODO: laszlonemeth/magyarispell#9
# echo "  hungarian"
# cd "$SOURCES/hungarian/magyarispell-master" || exit
# LC_ALL=C make myspell
# cd ../../.. || exit

echo "  low-german"
cd "$SOURCES/low-german/dict_nds-master" || exit
make nds_de.aff nds_de.dic
cd ../../.. || exit

# echo "  macedonian"
# cd "$SOURCES/macedonian/hunspell-mk-master" || exit
# if [ ! -e "release" ]; then
#   bash ./build_release.sh
# fi
# cd ../../.. || exit

echo "  norwegian"
cd "$SOURCES/norwegian" || exit
if [ ! -e "no" ]; then
  unzip "no_NO-pack2-2.2.zip" -d "no"
fi
if [ ! -e "nb" ]; then
  unzip "no/nb_NO.zip" -d "nb"
fi
if [ ! -e "nn" ]; then
  unzip "no/nn_NO.zip" -d "nn"
fi
cd ../.. || exit

if [ ! -e "$SOURCES/ukrainian/license" ]; then
  echo "  ukrainian"
  wget "https://raw.githubusercontent.com/brown-uk/dict_uk/master/LICENSE" -O "$SOURCES/ukrainian/license"
  printf "  $(green "license")\n"
fi

printf "$(bold "Made")!\n\n"

#####################################################################
# DICTIONARIES ######################################################
#####################################################################

printf "$(bold "Generating")...\n"

generate "bg" "bulgarian" \
  "OOo-full-pack-bg-4.3/bg_BG.dic" "CP1251" \
  "OOo-full-pack-bg-4.3/bg_BG.aff" "CP1251" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "OOo-full-pack-bg-4.3/README_spell.bulgarian" "CP1251"
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
  "(GPL-2.0 OR GPL-3.0)" "hunspell/Copyright" "UTF-8"
generate "de-AT" "german" \
  "hunspell/de_AT.dic" "ISO8859-1" \
  "hunspell/de_AT.aff" "ISO8859-1" \
  "(GPL-2.0 OR GPL-3.0)" "hunspell/Copyright" "UTF-8"
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
  "eu_ES.dic" "UTF-8" \
  "eu_ES.aff" "UTF-8" \
  "GPL-2.0"
generate "fa" "persian" \
  "fa-IR.dic" "UTF-8" \
  "fa-IR.aff" "UTF-8" \
  "Apache-2.0" "README_fa_IR.txt" "UTF-8"
# TODO: Stava is down.
# generate "fo" "faroese" \
#   "fo_FO.dic" "ISO8859-1" \
#   "fo_FO.aff" "ISO8859-1" \
#   "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "LICENSE_en_US.txt" "UTF-8"
# French: use classic (“classique”) because the readme suggests so.
generate "fr" "french" \
  "fr-classique.dic" "UTF-8" \
  "fr-classique.aff" "UTF-8" \
  "MPL-2.0" "README_dict_fr.txt" "UTF-8"
generate "fur" "friulian" \
  "myspell-fur-12092005/fur_IT.dic" "ISO8859-1" \
  "myspell-fur-12092005/fur_IT.aff" "ISO8859-1" \
  "GPL-2.0" "myspell-fur-12092005/COPYING.txt" "ISO8859-1"
generate "fy" "frisian" \
  "frisian-master/generated/fy_NL.dic" "UTF-8" \
  "frisian-master/generated/fy_NL.aff" "UTF-8" \
  "GPL-3.0" "frisian-master/LICENSE" "UTF-8"
# TODO: kscanne/gaelspell#2
# generate "ga" "irish" \
#   "gaelspell-5.0/ga_IE.dic" "UTF-8" \
#   "gaelspell-5.0/ga_IE.aff" "UTF-8" \
#   "GPL-2.0" "gaelspell-5.0/LICENSES-en.txt" "UTF-8"
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
# TODO: laszlonemeth/magyarispell#9
# generate "hu" "hungarian" \
#   "hu_HU_u8_gen_alias.dic" "ISO8859-2" \
#   "hu_HU_u8_gen_alias.aff" "ISO8859-2" \
#   "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "README" "UTF-8"
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
generate "ka" "georgian" \
  "ka_GE.spell-master/dictionaries/ka_GE.dic" "UTF-8" \
  "ka_GE.spell-master/dictionaries/ka_GE.aff" "UTF-8" \
  "MIT" "ka_GE.spell-master/LICENSE.mit" "UTF-8"
generate "ko" "korean" \
  "ko-aff-dic-0.7.1/ko.dic" "UTF-8" \
  "ko-aff-dic-0.7.1/ko.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "ko-aff-dic-0.7.1/LICENSE" "UTF-8"
generate "la" "latin" \
  "la/universal/la.dic" "UTF-8" \
  "la/universal/la.aff" "UTF-8" \
  "GPL-2.0" "la/README_la.txt" "CP1252"
generate "lb" "luxembourgish" \
  "dictionary-lb-lu-master/lb_LU.dic" "UTF-8" \
  "dictionary-lb-lu-master/lb_LU.aff" "UTF-8" \
  "EUPL-1.1" "dictionary-lb-lu-master/LICENSE.txt" "UTF-8"
generate "lt" "lithuanian" \
  "myspell-lt-1.3/lt_LT.dic" "ISO8859-13" \
  "myspell-lt-1.3/lt_LT.aff" "ISO8859-13" \
  "BSD-3-Clause" "myspell-lt-1.3/COPYING" "UTF-8"
generate "ltg" "latgalian" \
  "ltg_LV.dic" "UTF-8" \
  "ltg_LV.aff" "UTF-8" \
  "LGPL-2.1" "README_ltg_LV.txt" "UTF-8"
generate "lv" "latvian" \
  "lv_LV.dic" "UTF-8" \
  "lv_LV.aff" "UTF-8" \
  "LGPL-2.1" "README_lv_LV.txt" "UTF-8"
# generate "mk" "macedonian" \
#   "hunspell-mk-master/release/mk.dic" "UTF-8" \
#   "hunspell-mk-master/release/mk.aff" "UTF-8" \
#   "GPL-3.0" "hunspell-mk-master/release/LICENCE.txt" "UTF-8"
generate "mn" "mongolian" \
  "mn_MN.dic" "UTF-8" \
  "mn_MN.aff" "UTF-8" \
  "GPL-2.0" "README_mn_MN.txt" "UTF-8"
generate "ne" "nepali" \
  "ne_NP.dic" "UTF-8" \
  "ne_NP.aff" "UTF-8" \
  "LGPL-2.1" "README_ne_NP.txt" "UTF-8"
generate "nb" "norwegian" \
  "nb/nb_NO.dic" "ISO8859-1" \
  "nb/nb_NO.aff" "ISO8859-1" \
  "GPL-2.0" "nb/README_nb_NO.txt" "ISO8859-1"
generate "nds" "low-german" \
  "dict_nds-master/nds_de.dic" "UTF-8" \
  "dict_nds-master/nds_de.aff" "UTF-8" \
  "GPL-3.0" "dict_nds-master/README" "UTF-8"
generate "nl" "dutch" \
  "dutch-master/result/hunspell-nl/usr/share/hunspell/nl.dic" "UTF-8" \
  "dutch-master/result/hunspell-nl/usr/share/hunspell/nl.aff" "UTF-8" \
  "(BSD-3-Clause OR CC-BY-3.0)" "dutch-master/LICENSE" "UTF-8"
generate "nn" "norwegian" \
  "nn/nn_NO.dic" "ISO8859-1" \
  "nn/nn_NO.aff" "ISO8859-1" \
  "GPL-2.0" "nn/README_nn_NO.txt" "ISO8859-1"
generate "pl" "polish" \
  "pl_PL.dic" "ISO8859-2" \
  "pl_PL.aff" "ISO8859-2" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-2.0)" "README_en.txt" "UTF-8"
generate "pt" "portuguese" \
  "pt_PT.dic" "UTF-8" \
  "pt_PT.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "README_pt_PT.txt" "CP1252"
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
  "GPL-3.0" "hunspell-rw-master/LICENSE" "UTF-8"
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
generate "tk" "turkmen" \
  "turkmen-spell-check-dictionary-master/tk_TM.dic" "UTF-8" \
  "turkmen-spell-check-dictionary-master/tk_TM.aff" "UTF-8"
generate "tr" "turkish" \
  "dictionaries/tr-TR.dic" "UTF-8" \
  "dictionaries/tr-TR.aff" "UTF-8" \
  "MIT"
generate "uk" "ukrainian" \
  "uk_UA.dic" "UTF-8" \
  "uk_UA.aff" "UTF-8" \
  "GPL-3.0" "LICENSE" "UTF-8"
generate "vi" "vietnamese" \
  "dictionaries/vi_VN.dic" "UTF-8" \
  "dictionaries/vi_VN.aff" "UTF-8" \
  "GPL-2.0" "LICENSES-en.txt" "UTF-8"

printf "$(bold "Generated")!\n\n"
