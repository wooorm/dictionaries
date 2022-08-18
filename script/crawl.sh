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
      sed '1s/^\xEF\xBB\xBF//' | # BOM
      sed 's/[ 	]*$//' | # Trailing white-space
      sed 's/\r$//' | # Carriage return
      sed -e '$a\' # EOF EOL
    ) < "$SOURCE/$3" > "$dictionary/index.dic"
    printf "   $(green "✓") index.dic (from $4)\n"
  else
    printf "   $(red "𐄂 Could not find $3 file")\n"
  fi

  if [ -e "$SOURCE/$5" ]; then
    (
      iconv -f "$6" -t "UTF-8" | # Encoding
      sed "s/SET .*/SET UTF-8/" | # Encoding Pragma
      sed '1s/^\xEF\xBB\xBF//' | # BOM
      sed 's/[ 	]*$//' | # Trailing white-space
      sed 's/\r$//' | # Carriage return
      sed -e '$a\' # EOF EOL
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
      sed '1s/^\xEF\xBB\xBF//' | # BOM
      sed 's/[ 	]*$//' | # Trailing white-space
      sed 's/\r$//' | # Carriage return
      sed -e '$a\' # EOF EOL
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
# TODO: https://github.com/hyspell/HySpell_3.0.1/issues/1
# western: hy-arevmda -> BCP now recommends hyw (always non-reformed)
# eastern: hy-arevela -> BCP now recommends hy (always reformed, except in Iran)
# See also: https://www.evnreport.com/raw-unfiltered/international-recognition-for-the-western-armenian-language
crawl "armenian-eastern" \
  "https://sites.google.com/site/araktransfer/home/spell-checkers" \
  "https://sites.google.com/site/araktransfer/home/spell-checkers/hy_AM_e_1940_dict-1.1.oxt"
crawl "armenian-western" \
  "https://sites.google.com/site/araktransfer/home/spell-checkers" \
  "https://sites.google.com/site/araktransfer/home/spell-checkers/hy_AM_western-1.0.oxt"
# See: http://xuxen.eus/deskargatu, click “hunspell”, see the yellow thing.
crawl "basque" \
  "http://xuxen.eus/eu/home" \
  "http://xuxen.eus/static/hunspell/xuxen_5.1_hunspell.zip"
# Nothing:
crawl "breton" \
  "https://github.com/Drouizig/hunspell-br" \
  "https://github.com/Drouizig/hunspell-br/archive/master.zip"
# See <http://bgoffice.sourceforge.net/ooo/index.html>, pick the first `тук` (which goes to “Bulgarian language support”)
crawl "bulgarian" \
  "http://bgoffice.sourceforge.net" \
  "https://master.dl.sourceforge.net/project/bgoffice/OpenOffice.org%20Full%20Pack/4.3/OOo-full-pack-bg-4.3.zip?viasf=1"
# See <https://github.com/Softcatala/catalan-dict-tools/releases>, pick the latest.
crawl "catalan" \
  "https://github.com/Softcatala/catalan-dict-tools" \
  "https://github.com/Softcatala/catalan-dict-tools/releases/download/v3.0.7/ca-hunspell.zip"
# Same as `catalan`
crawl "catalan-valencian" \
  "https://github.com/Softcatala/catalan-dict-tools" \
  "https://github.com/Softcatala/catalan-dict-tools/releases/download/v3.0.7/ca-valencia-hunspell.zip"
# Nothing:
crawl "croatian" \
  "https://github.com/krunose/hunspell-hr" \
  "https://github.com/krunose/hunspell-hr/archive/master.zip"
# See: <http://www.translatoblog.cz/hunspell/> (see `tady`). Or use a custom Google search on
# that site to look for “hunspell” for recent entries?
crawl "czech" \
  "http://www.translatoblog.cz/hunspell/" \
  "http://www.translatoblog.cz/wp-content/uploads/2021/03/hunspell_cs.zip"
# See <https://stavekontrolden.dk/?dictionaries=1>, get the OXT link.
crawl "danish" \
  "https://stavekontrolden.dk" \
  "https://stavekontrolden.dk/dictionaries/da_DK/da_DK-2.7.026.oxt"
# Nothing:
crawl "dutch" \
  "https://github.com/OpenTaal/opentaal-hunspell" \
  "https://github.com/OpenTaal/opentaal-hunspell/archive/master.zip"
# Go to the link, get the latest.
crawl "english" \
  "http://extensions.openoffice.org/en/project/english-dictionaries-apache-openoffice" \
  "https://altushost-swe.dl.sourceforge.net/project/aoo-extensions/17102/80/dict-en-20220801_aoo.oxt"
# Go to the link, go to “Additional Hunspell Dictionaries”, go to “Parent folder”.
crawl "english-gb" \
  "http://wordlist.aspell.net/dicts/" \
  "https://netcologne.dl.sourceforge.net/project/wordlist/speller/2020.12.07/hunspell-en_GB-ise-2020.12.07.zip"
# Same as `english-gb`
crawl "english-american" \
  "http://wordlist.aspell.net/dicts/" \
  "https://netcologne.dl.sourceforge.net/project/wordlist/speller/2020.12.07/hunspell-en_US-2020.12.07.zip"
# Same as `english-gb`
crawl "english-canadian" \
  "http://wordlist.aspell.net/dicts/" \
  "https://netcologne.dl.sourceforge.net/project/wordlist/speller/2020.12.07/hunspell-en_CA-2020.12.07.zip"
# Same as `english-gb`
crawl "english-australian" \
  "http://wordlist.aspell.net/dicts/" \
  "https://netcologne.dl.sourceforge.net/project/wordlist/speller/2020.12.07/hunspell-en_AU-2020.12.07.zip"
# Hasn’t updated in 20 years 🤷‍♂️
crawl "esperanto" \
  "http://www.esperantilo.org/index_en.html" \
  "http://www.esperantilo.org/evortaro.zip"
# Probably nothing.
# If not: go to <https://stava.glasir.fo>, click the tiny plus in the left bottom, scroll to `Hunspell`.
crawl "faroese" \
  "https://stava.glasir.fo" \
  "https://stava.glasir.fo/download/hunspell.zip"
# Go to <https://grammalecte.net/#download>, copy the url of “GRAMMALECTE pour LibreOffice 5.3+”.
crawl "french" \
  "https://grammalecte.net" \
  "https://grammalecte.net/grammalecte/oxt/Grammalecte-fr-v2.1.2.oxt"
# Nothing:
crawl "frisian" \
  "https://github.com/PanderMusubi/frisian" \
  "https://github.com/PanderMusubi/frisian/archive/master.zip"
# Not updated in 17 years.
# Go to <http://digilander.libero.it/paganf/coretors/dizionaris.html>,
# copy/paste the URL of `myspell-fur-...` at the bottom.
crawl "friulian" \
  "http://digilander.libero.it/paganf/coretors/dizionaris.html" \
  "http://digilander.libero.it/paganf/coretors/myspell-fur-12092005.zip"
# Nothing:
crawl "gaelic" \
  "https://github.com/kscanne/hunspell-gd" \
  "https://github.com/kscanne/hunspell-gd/archive/master.zip"
# Nothing:
crawl "galician" \
  "https://github.com/meixome/hunspell-gl" \
  "https://github.com/meixome/hunspell-gl/archive/master.zip"
# Nothing:
crawl "georgian" \
  "https://github.com/gamag/ka_GE.spell" \
  "https://github.com/gamag/ka_GE.spell/archive/master.zip"
# Not updated in 6 years.
# Go to <https://www.j3e.de/ispell/igerman98/dict/>, get the latest
# `igerman98-20*` tarball.
crawl "german" \
  "https://www.j3e.de/ispell/igerman98/index_en.html" \
  "https://j3e.de/ispell/igerman98/dict/igerman98-20161207.tar.bz2"
# Nothing:
crawl "greek" \
  "https://github.com/stevestavropoulos/elspell" \
  "https://github.com/stevestavropoulos/elspell/archive/master.zip"
# Go to <https://thepolytonicproject.gr/spell/>, click the image/button:
# “Ἐγκατάσταση σὲ OpenOffice / LibreOffice”, and get the latest from sourceforge.
crawl "greek-polyton" \
  "https://thepolytonicproject.gr/spell" \
  "https://altushost-swe.dl.sourceforge.net/project/greekpolytonicsp/greek_polytonic_2.0.7.oxt"
# Go to <http://hspell.ivrix.org.il/download.html>, copy/paste the URL of the
# latest release
crawl "hebrew" \
  "http://hspell.ivrix.org.il" \
  "http://hspell.ivrix.org.il/hspell-1.4.tar.gz"
# TODO, this is impossible to build? <https://github.com/laszlonemeth/magyarispell/issues/9>
# For now, go to: <https://github.com/crash5/mozilla-hungarian-spellchecker/releases>,
# copy/paste the URL of the latest `.zip` file.
crawl "hungarian" \
  "https://github.com/laszlonemeth/magyarispell" \
  "https://github.com/crash5/mozilla-hungarian-spellchecker/releases/download/2022.02.18.09.36/MagyarIspell_67770a2.zip"
# Hasn’t updated in 8 years.
# Go to <https://addons.thunderbird.net/en-US/thunderbird/addon/dict-ia/>,
# copy/paste the URL for “Download Now” (but clean it).
crawl "interlingua" \
  "https://addons.thunderbird.net/en-US/thunderbird/addon/dict-ia/" \
  "https://addons.thunderbird.net/user-media/addons/_attachments/514646/interlingua_sownik_ortograficzny-2014.05.30-tb+fx.xpi"
# Nothing:
crawl "interlingue" \
  "https://github.com/Carmina16/hunspell-ie" \
  "https://github.com/Carmina16/hunspell-ie/archive/master.zip"
# Go to <https://github.com/kscanne/gaelspell/releases>, get the latest.
# Note: hasn’t been a release in 3 years but 5.2 is planned apparently.
crawl "irish" \
  "https://github.com/kscanne/gaelspell" \
  "https://github.com/kscanne/gaelspell/releases/download/v5.1/hunspell-ga-5.1.zip"
# Down, unfortunately :'(
# crawl "italian" \
#   "http://www.plio.it" \
#   "https://iweb.dl.sourceforge.net/project/aoo-extensions/1204/14/dict-it.oxt"
# Nothing:
crawl "kinyarwanda" \
  "https://github.com/kscanne/hunspell-rw" \
  "https://github.com/kscanne/hunspell-rw/archive/master.zip"
# Nothing:
crawl "klingon" \
  "https://github.com/PanderMusubi/klingon" \
  "https://github.com/PanderMusubi/klingon/archive/master.zip"
# Go to <https://github.com/spellcheck-ko/hunspell-dict-ko/releases>,
# copy/paste the URL of the latest `.zip`.
crawl "korean" \
  "https://github.com/spellcheck-ko/hunspell-dict-ko" \
  "https://github.com/spellcheck-ko/hunspell-dict-ko/releases/download/0.7.92/ko-aff-dic-0.7.92.zip"
# Go to <http://dict.dv.lv/download.php?prj=la>, copy the url of the latest `.oxt`.
crawl "latgalian" \
  "http://dict.dv.lv/home.php?prj=la" \
  "http://dict.dv.lv/download/ltg_LV-0.1.5.oxt"
# Go to <http://dict.dv.lv/download.php?prj=lv>, copy the url of the latest `.oxt`.
crawl "latvian" \
  "http://dict.dv.lv/home.php?prj=lv" \
  "http://dict.dv.lv/download/lv_LV-1.4.0.oxt"
# Hasn’t been updates in 10 years.
crawl "latin" \
  "https://extensions.openoffice.org/project/dict-la" \
  "https://deac-fra.dl.sourceforge.net/project/aoo-extensions/1141/3/dict-la_2013-03-31.oxt"
# Nothing.
crawl "libreoffice" \
  "https://github.com/LibreOffice/dictionaries" \
  "https://github.com/LibreOffice/dictionaries/archive/master.zip"
# Go to <https://github.com/ispell-lt/ispell-lt/releases/>,
# get the latest myspell.
crawl "lithuanian" \
  "https://github.com/ispell-lt/ispell-lt" \
  "https://github.com/ispell-lt/ispell-lt/releases/download/rel-1.3.2/myspell-lt-1.3.2.zip"
# Nothing.
crawl "low-german" \
  "https://github.com/tdf/dict_nds" \
  "https://github.com/tdf/dict_nds/archive/master.zip"
# Nothing.
crawl "luxembourgish" \
  "https://github.com/spellchecker-lu/dictionary-lb-lu" \
  "https://github.com/spellchecker-lu/dictionary-lb-lu/archive/master.zip"
# It was taken offline unfortunately :'(
# crawl "macedonian" \
#   "https://github.com/dimztimz/hunspell-mk" \
#   "https://github.com/dimztimz/hunspell-mk/archive/master.zip"
# Nothing:
crawl "mongolian" \
  "https://github.com/bataak/dict-mn" \
  "https://github.com/bataak/dict-mn/archive/main.zip"
# Hasn’t been updated in 10 years.
crawl "nepali" \
  "http://ltk.org.np" \
  "http://ltk.org.np/downloads/ne_NP_dict.zip"
# Website offline :'(
crawl "norwegian" \
  "http://no.speling.org" \
  "https://alioth-archive.debian.org/releases/spell-norwegian/spell-norwegian/spell-norwegian-latest.zip"
# Go to <https://gitlab.com/taissou/hunspell-files-for-occitan-lengadocian>,
# click the `corrector_occitan_lengadocian_….oxt` (last?), copy/paste the “Download” URL
crawl "occitan" \
  "https://gitlab.com/taissou/hunspell-files-for-occitan-lengadocian" \
  "https://gitlab.com/taissou/hunspell-files-for-occitan-lengadocian/-/raw/master/corrector_occitan_lengadocian_1-2.oxt"
# Go to <https://github.com/b00f/lilak/releases>, get the latest `fa-IR.zip`.
crawl "persian" \
  "https://github.com/b00f/lilak" \
  "https://github.com/b00f/lilak/releases/download/v3.3/fa-IR.zip"
# Unknown, I contacted an old maintainer.
crawl "polish" \
  "http://extensions.openoffice.org/en/project/polish-dictionary-pack" \
  "https://master.dl.sourceforge.net/project/aoo-extensions/806/4/pl-dict.oxt?viasf=1"
# Go to <https://natura.di.uminho.pt/download/sources/Dictionaries/hunspell/>,
# get the last one **before** `hunspell-pt_PT-preao*`
crawl "portuguese-pt" \
  "https://natura.di.uminho.pt" \
  "https://natura.di.uminho.pt/download/sources/Dictionaries/hunspell/hunspell-pt_PT-20220621.tar.gz"
# Go to <https://rospell.wordpress.com/download/>,
# get the hunspell one.
crawl "romanian" \
  "https://rospell.wordpress.com" \
  "https://master.dl.sourceforge.net/project/rospell/Romanian%20dictionaries/dict-3.3.10/ro_RO.3.3.10.zip?viasf=1"
# Not updated in 9 years.
# Go to <https://bitbucket.org/Shaman_Alex/russian-dictionary-hunspell/downloads/>,
# (or find the link to that on <https://code.google.com/archive/p/hunspell-ru/>).
crawl "russian" \
  "https://code.google.com/archive/p/hunspell-ru/" \
  "https://bitbucket.org/Shaman_Alex/russian-dictionary-hunspell/downloads/ru_RU_UTF-8_20131101.zip"
# Nothing.
crawl "serbian" \
  "https://github.com/grakic/hunspell-sr" \
  "https://github.com/grakic/hunspell-sr/archive/master.zip"
# Hasn’t been updated in 10 years, but:
# Go to <http://www.sk-spell.sk.cx/hunspell-sk>, get the most recent `hunspell-sk`.
crawl "slovak" \
  "http://www.sk-spell.sk.cx" \
  "http://www.sk-spell.sk.cx/file_download/92/hunspell-sk-20110228.zip"
# Go to <https://extensions.libreoffice.org/extensions/slovenian-dictionary-pack/>,
# get the top “download”.
crawl "slovenian" \
  "https://extensions.libreoffice.org/extensions/slovenian-dictionary-pack/" \
  "https://extensions.libreoffice.org/assets/downloads/752/1659538154/pack-sl.oxt"
# Go to <https://github.com/sbosio/rla-es/releases>,
# hopefully only the version number changes 😅
crawl "spanish" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es.oxt"
crawl "spanish-ar" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_AR.oxt"
crawl "spanish-bo" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_BO.oxt"
crawl "spanish-cl" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_CL.oxt"
crawl "spanish-co" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_CO.oxt"
crawl "spanish-cr" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_CR.oxt"
crawl "spanish-cu" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_CU.oxt"
crawl "spanish-do" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_DO.oxt"
crawl "spanish-ec" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_EC.oxt"
crawl "spanish-es" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_ES.oxt"
crawl "spanish-gt" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_GT.oxt"
crawl "spanish-hn" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_HN.oxt"
crawl "spanish-mx" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_MX.oxt"
crawl "spanish-ni" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_NI.oxt"
crawl "spanish-pa" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_PA.oxt"
crawl "spanish-pe" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_PE.oxt"
crawl "spanish-ph" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_PH.oxt"
crawl "spanish-pr" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_PR.oxt"
crawl "spanish-py" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_PY.oxt"
crawl "spanish-sv" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_SV.oxt"
crawl "spanish-us" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_US.oxt"
crawl "spanish-uy" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_UY.oxt"
crawl "spanish-ve" \
  "https://github.com/sbosio/rla-es" \
  "https://github.com/sbosio/rla-es/releases/download/v2.6/es_VE.oxt"
# Go to <https://extensions.libreoffice.org/extensions/swedish-spelling-dictionary-den-stora-svenska-ordlistan>,
# get the top “download”.
crawl "swedish" \
  "https://extensions.libreoffice.org/extensions/swedish-spelling-dictionary-den-stora-svenska-ordlistan" \
  "https://extensions.libreoffice.org/assets/downloads/z/ooo-swedish-dict-2-42.oxt"
# Hasn’t been updated in 7 years, but:
# Go to <http://extensions.openoffice.org/en/project/turkish-spellcheck-dictionary>,
# get the top.
crawl "turkish" \
  "http://extensions.openoffice.org/en/project/turkish-spellcheck-dictionary" \
  "https://kumisystems.dl.sourceforge.net/project/aoo-extensions/18079/0/oo-turkish-dict-v1.3.oxt"
# Nothing.
crawl "turkmen" \
  "https://github.com/nazartm/turkmen-spell-check-dictionary" \
  "https://github.com/nazartm/turkmen-spell-check-dictionary/archive/master.zip"
# Go to <https://github.com/brown-uk/dict_uk/releases>,
# get the top `hunspell-uk`.
crawl "ukrainian" \
  "https://github.com/brown-uk/dict_uk" \
  "https://github.com/brown-uk/dict_uk/releases/download/v5.8.0/hunspell-uk_UA_5.8.0.zip"
# Hasn’t updated in 8 years, but:
# Go to <https://github.com/1ec5/hunspell-vi/releases>.
crawl "vietnamese" \
  "https://github.com/1ec5/hunspell-vi" \
  "https://github.com/1ec5/hunspell-vi/releases/download/v2.2.0/vi_spellchecker_OOo3.oxt"
# Nothing.
crawl "welsh-gb" \
  "https://github.com/techiaith/hunspell-cy" \
  "https://github.com/techiaith/hunspell-cy/archive/master.zip"

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

if [ ! -e "$SOURCES/turkish/license" ]; then
  echo "  turkish"
  wget "https://raw.githubusercontent.com/hrzafer/hunspell-tr/master/LICENSE" -O "$SOURCES/turkish/license"
  printf "  $(green "license")\n"
fi

if [ ! -e "$SOURCES/galician/hunspell-gl-master/gl_ES.aff" ]; then
  echo "  galician"
  wget "https://github.com/meixome/hunspell-gl/releases/download/18.07/gl_ES.aff" -O "$SOURCES/galician/hunspell-gl-master/gl_ES.aff"
  wget "https://github.com/meixome/hunspell-gl/releases/download/18.07/gl_ES.dic" -O "$SOURCES/galician/hunspell-gl-master/gl_ES.dic"
  printf "  $(green "aff and dic")\n"
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
  "hunspell-br-master/br_FR.dic" "UTF-8" \
  "hunspell-br-master/br_FR.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "hunspell-br-master/README.txt" "UTF-8"
generate "ca" "catalan" \
  "catalan.dic" "UTF-8" \
  "catalan.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1)" "LICENSE" "UTF-8"
generate "ca-valencia" "catalan-valencian" \
  "catalan-valencia.dic" "UTF-8" \
  "catalan-valencia.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1)" "LICENSE" "UTF-8"
generate "cs" "czech" \
  "cs_CZ.dic" "UTF-8" \
  "cs_CZ.aff" "UTF-8" \
  "GPL-2.0" "readme.txt" "UTF-8"
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
generate "en" "english-american" \
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
generate "es" "spanish-ES" \
  "es_ES.dic" "UTF-8" \
  "es_ES.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-AR" "spanish-ar" \
  "es_AR.dic" "UTF-8" \
  "es_AR.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-BO" "spanish-bo" \
  "es_BO.dic" "UTF-8" \
  "es_BO.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-CL" "spanish-cl" \
  "es_CL.dic" "UTF-8" \
  "es_CL.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-CO" "spanish-co" \
  "es_CO.dic" "UTF-8" \
  "es_CO.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-CR" "spanish-cr" \
  "es_CR.dic" "UTF-8" \
  "es_CR.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-CU" "spanish-cu" \
  "es_CU.dic" "UTF-8" \
  "es_CU.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-DO" "spanish-do" \
  "es_DO.dic" "UTF-8" \
  "es_DO.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-EC" "spanish-ec" \
  "es_EC.dic" "UTF-8" \
  "es_EC.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-GT" "spanish-gt" \
  "es_GT.dic" "UTF-8" \
  "es_GT.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-HN" "spanish-hn" \
  "es_HN.dic" "UTF-8" \
  "es_HN.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-MX" "spanish-mx" \
  "es_MX.dic" "UTF-8" \
  "es_MX.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-NI" "spanish-ni" \
  "es_NI.dic" "UTF-8" \
  "es_NI.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-PA" "spanish-pa" \
  "es_PA.dic" "UTF-8" \
  "es_PA.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-PE" "spanish-pe" \
  "es_PE.dic" "UTF-8" \
  "es_PE.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-PH" "spanish-ph" \
  "es_PH.dic" "UTF-8" \
  "es_PH.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-PR" "spanish-pr" \
  "es_PR.dic" "UTF-8" \
  "es_PR.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-PY" "spanish-py" \
  "es_PY.dic" "UTF-8" \
  "es_PY.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-SV" "spanish-sv" \
  "es_SV.dic" "UTF-8" \
  "es_SV.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-US" "spanish-us" \
  "es_US.dic" "UTF-8" \
  "es_US.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-UY" "spanish-uy" \
  "es_UY.dic" "UTF-8" \
  "es_UY.aff" "UTF-8" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-1.1)" "README.txt" "UTF-8"
generate "es-VE" "spanish-ve" \
  "es_VE.dic" "UTF-8" \
  "es_VE.aff" "UTF-8" \
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
  "fa-IR/fa-IR.dic" "UTF-8" \
  "fa-IR/fa-IR.aff" "UTF-8" \
  "Apache-2.0" "fa-IR/license" "UTF-8"
generate "fo" "faroese" \
  "fo_FO.dic" "ISO8859-1" \
  "fo_FO.aff" "ISO8859-1" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "LICENSE_en_US.txt" "UTF-8"
# French: use classic (“classique”) because the readme suggests so.
generate "fr" "french" \
  "dictionaries/fr-classique.dic" "UTF-8" \
  "dictionaries/fr-classique.aff" "UTF-8" \
  "MPL-2.0" "dictionaries/README_dict_fr.txt" "UTF-8"
generate "fur" "friulian" \
  "myspell-fur-12092005/fur_IT.dic" "ISO8859-1" \
  "myspell-fur-12092005/fur_IT.aff" "ISO8859-1" \
  "GPL-2.0" "myspell-fur-12092005/COPYING.txt" "ISO8859-1"
generate "fy" "frisian" \
  "frisian-master/generated/fy_NL.dic" "UTF-8" \
  "frisian-master/generated/fy_NL.aff" "UTF-8" \
  "GPL-3.0" "frisian-master/LICENSE" "UTF-8"
generate "ga" "irish" \
  "ga_IE.dic" "UTF-8" \
  "ga_IE.aff" "UTF-8" \
  "GPL-2.0" "README_ga_IE.txt" "UTF-8"
generate "gd" "gaelic" \
  "hunspell-gd-master/gd_GB.dic" "UTF-8" \
  "hunspell-gd-master/gd_GB.aff" "UTF-8" \
  "GPL-3.0" "hunspell-gd-master/README_gd_GB.txt" "UTF-8"
generate "gl" "galician" \
  "hunspell-gl-master/gl_ES.dic" "UTF-8" \
  "hunspell-gl-master/gl_ES.aff" "UTF-8" \
  "GPL-3.0" "hunspell-gl-master/LICENSE" "UTF-8"
generate "he" "hebrew" \
  "he.dic" "UTF-8" \
  "he.aff" "UTF-8" \
  "AGPL-3.0" "LICENSE" "UTF-8"
generate "hr" "croatian" \
  "hunspell-hr-master/hr_HR.dic" "UTF-8" \
  "hunspell-hr-master/hr_HR.aff" "UTF-8" \
  "(LGPL-2.1 OR SISSL)" "hunspell-hr-master/README_hr_HR.txt" "UTF-8"
# TODO: laszlonemeth/magyarispell#9
generate "hu" "hungarian" \
  "hu_HU.dic" "ISO8859-2" \
  "hu_HU.aff" "ISO8859-2" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "README.en" "UTF-8"
generate "hy" "armenian-eastern" \
  "hy_am_e_1940.dic" "UTF-8" \
  "hy_am_e_1940.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "COPYING" "UTF-8"
generate "hyw" "armenian-western" \
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
# Offline...
# generate "it" "italian" \
#   "dictionaries/it_IT.dic" "UTF-8" \
#   "dictionaries/it_IT.aff" "UTF-8" \
#   "GPL-3.0" "dictionaries/README.txt" "UTF-8"
generate "ka" "georgian" \
  "ka_GE.spell-master/dictionaries/ka_GE.dic" "UTF-8" \
  "ka_GE.spell-master/dictionaries/ka_GE.aff" "UTF-8" \
  "MIT" "ka_GE.spell-master/LICENSE.mit" "UTF-8"
generate "ko" "korean" \
  "ko-aff-dic-0.7.92/ko.dic" "UTF-8" \
  "ko-aff-dic-0.7.92/ko.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "ko-aff-dic-0.7.92/LICENSE.md"
generate "la" "latin" \
  "la/universal/la.dic" "UTF-8" \
  "la/universal/la.aff" "UTF-8" \
  "GPL-2.0" "la/README_la.txt" "CP1252"
generate "lb" "luxembourgish" \
  "dictionary-lb-lu-master/lb_LU.dic" "UTF-8" \
  "dictionary-lb-lu-master/lb_LU.aff" "UTF-8" \
  "EUPL-1.1" "dictionary-lb-lu-master/LICENSE.txt" "UTF-8"
generate "lt" "lithuanian" \
  "myspell-lt-1.3.2/lt_LT.dic" "ISO8859-13" \
  "myspell-lt-1.3.2/lt_LT.aff" "ISO8859-13" \
  "BSD-3-Clause" "myspell-lt-1.3.2/COPYING" "UTF-8"
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
  "dict-mn-main/mn_MN/mn_MN.dic" "UTF-8" \
  "dict-mn-main/mn_MN/mn_MN.aff" "UTF-8" \
  "LPPL-1.3c" "dict-mn-main/mn_MN/README_mn_MN.txt" "UTF-8"
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
# Dutch is down. They seem to be working on a new version.
generate "nl" "dutch" \
  "opentaal-hunspell-master/nl.dic" "UTF-8" \
  "opentaal-hunspell-master/nl.aff" "UTF-8" \
  "(BSD-3-Clause OR CC-BY-3.0)" "opentaal-hunspell-master/LICENSE.txt" "UTF-8"
generate "nn" "norwegian" \
  "nn/nn_NO.dic" "ISO8859-1" \
  "nn/nn_NO.aff" "ISO8859-1" \
  "GPL-2.0" "nn/README_nn_NO.txt" "ISO8859-1"
generate "oc" "occitan" \
  "oc_FR.dic" "UTF-8" \
  "oc_FR.aff" "UTF-8" \
  "GPL-2.0" "LICENSES-en.txt" "UTF-8"
generate "pl" "polish" \
  "pl_PL.dic" "ISO8859-2" \
  "pl_PL.aff" "ISO8859-2" \
  "(GPL-3.0 OR LGPL-3.0 OR MPL-2.0)" "README_en.txt" "UTF-8"
generate "pt-PT" "portuguese-pt" \
  "pt_PT.dic" "UTF-8" \
  "pt_PT.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "README_pt_PT.txt" "CP1252"
generate "pt" "libreoffice" \
  "dictionaries-master/pt_BR/pt_BR.dic" "UTF-8" \
  "dictionaries-master/pt_BR/pt_BR.aff" "UTF-8" \
  "(LGPL-3.0 OR MPL-2.0)" "dictionaries-master/pt_BR/README_en.txt" "UTF-8"
generate "ro" "romanian" \
  "ro_RO.dic" "UTF-8" \
  "ro_RO.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "README" "UTF-8"
generate "ru" "russian" \
  "ru_RU.dic" "UTF-8" \
  "ru_RU.aff" "UTF-8" \
  "LGPL-3.0"
generate "rw" "kinyarwanda" \
  "hunspell-rw-master/rw_RW.dic" "ISO8859-1" \
  "hunspell-rw-master/rw_RW.aff" "ISO8859-1" \
  "GPL-3.0" "hunspell-rw-master/LICENSE" "UTF-8"
generate "sk" "slovak" \
  "hunspell-sk-20110228/sk_SK.dic" "UTF-8" \
  "hunspell-sk-20110228/sk_SK.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1)" "hunspell-sk-20110228/doc/Copyright" "UTF-8"
generate "sl" "slovenian" \
  "sl_SI.dic" "ISO8859-2" \
  "sl_SI.aff" "ISO8859-2" \
  "(GPL-3.0 OR LGPL-2.1)" "README_sl_SI.txt" "UTF-8"
generate "sr" "serbian" \
  "hunspell-sr-master/sr.dic" "UTF-8" \
  "hunspell-sr-master/sr.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1 OR CC-BY-SA-3.0)" "hunspell-sr-master/README_sr.txt" "UTF-8"
generate "sr-Latn" "serbian" \
  "hunspell-sr-master/sr-Latn.dic" "UTF-8" \
  "hunspell-sr-master/sr-Latn.aff" "UTF-8" \
  "(GPL-2.0 OR LGPL-2.1 OR MPL-1.1 OR CC-BY-SA-3.0)" "hunspell-sr-master/README-sr-Latn.txt" "UTF-8"
generate "sv" "swedish" \
  "dictionaries/sv_SE.dic" "UTF-8" \
  "dictionaries/sv_SE.aff" "UTF-8" \
  "LGPL-3.0" "LICENSE_en_US.txt" "UTF-8"
generate "sv-FI" "swedish" \
  "dictionaries/sv_FI.dic" "UTF-8" \
  "dictionaries/sv_FI.aff" "UTF-8" \
  "LGPL-3.0" "LICENSE_en_US.txt" "UTF-8"
generate "tk" "turkmen" \
  "turkmen-spell-check-dictionary-master/tk_TM.dic" "UTF-8" \
  "turkmen-spell-check-dictionary-master/tk_TM.aff" "UTF-8" \
  "Apache-2.0" "turkmen-spell-check-dictionary-master/LICENSE" "UTF-8"
generate "tlh" "klingon" \
  "klingon-master/generated/tlh.dic" "UTF-8" \
  "klingon-master/generated/tlh.aff" "UTF-8" \
  "Apache-2.0" "klingon-master/LICENSE" "UTF-8"
generate "tlh-Latn" "klingon" \
  "klingon-master/generated/tlh_Latn.dic" "UTF-8" \
  "klingon-master/generated/tlh_Latn.aff" "UTF-8" \
  "Apache-2.0" "klingon-master/LICENSE" "UTF-8"
generate "tr" "turkish" \
  "dictionaries/tr-TR.dic" "UTF-8" \
  "dictionaries/tr-TR.aff" "UTF-8" \
  "MIT" "license" "UTF-8"
generate "uk" "ukrainian" \
  "uk_UA.dic" "UTF-8" \
  "uk_UA.aff" "UTF-8" \
  "GPL-3.0" "LICENSE" "UTF-8"
generate "vi" "vietnamese" \
  "dictionaries/vi_VN.dic" "UTF-8" \
  "dictionaries/vi_VN.aff" "UTF-8" \
  "GPL-2.0" "LICENSES-en.txt" "UTF-8"
generate "cy" "welsh-gb" \
  "hunspell-cy-master/cy_GB.dic" "UTF-8" \
  "hunspell-cy-master/cy_GB.aff" "UTF-8" \
  "LGPL-3.0" "hunspell-cy-master/LICENCE" "UTF-8"

printf "$(bold "Generated")!\n\n"
