#!/usr/bin/env bash

CURRENT_DIR="$(pwd)"
BASENAME="$(basename ${CURRENT_DIR})"
SYSTEM_DIR="${CURRENT_DIR}/../System"
UCC="${SYSTEM_DIR}/ucc.exe"

if [[ -f "${BASENAME}.inc" ]]; then
    VERSION="$(sed 's/^#define __VERSION__ \(.*\)$/\1/p;d' ${BASENAME}.inc)"
else
    VERSION="UNKNOWN_VERSION"
fi
if [[ -d .git ]]; then
    BUILD_INFO="$(git branch | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/;s/\s\+/_/g')-$(git rev-parse --short HEAD)$([ -z "$(git status --porcelain 2>/dev/null | tail -n1)" ] || echo '-dirty')"
    VERSION_STRING="${VERSION}-${BUILD_INFO}"
else
    BUILD_INFO=""
    VERSION_STRING="${VERSION}"
fi
BUILD_DATE="$(date +"%a %d %b %Y %H:%M:%S %Z")"

NO_RESTORE=0
NO_PREPROCESS=0
RELEASE_BUILD=0

PREPROCESSED=0
EXIT_STATUS=0

restore () {
    if [[ ${NO_RESTORE} -eq 0 ]]; then
        rm -rf "${CURRENT_DIR}"/Classes
        mv -vf "${CURRENT_DIR}"/.Classes "${CURRENT_DIR}"/Classes
    fi
}

for ARG in "$@"; do
    case $ARG in
        "-h" | "--help")
            echo "Usage: build.sh [options]"
            echo
            echo " -n, --no-restore      : don't restore original Classes source tree when finishing"
            echo " -s, --skip-preprocess : skip the preprocessing phase entirely"
            echo " -r, --release         : compile with the __DEBUG__ macro undefined (for release builds)"
            exit 0
            ;;
        "-n" | "--no-restore")
            NO_RESTORE=1
            ;;
        "-s" | "--skip-preprocess")
            NO_PREPROCESS=1
            ;;
        "-r" | "--release")
            RELEASE_BUILD=1
            ;;
        *)
            echo "Unrecognized option \'$ARG\'"
            exit 1
            ;;
    esac
done

if [[ -n "$(lsof +D ${CURRENT_DIR}/Classes)" ]]; then echo 'Classes directory tree open in some program(s). Please close before continuing.' && exit 1; fi
if [[ ${RELEASE_BUILD} -eq 0 ]]; then
    echo -e "\e[92mBuild: DEBUG\e[0m"
else
    echo -e "\e[92mBuild: RELEASE\e[0m"
fi
echo -e "\e[92mVersion.......: ${VERSION}\e[0m"
echo -e "\e[92mBuild Info....: ${BUILD_INFO}\e[0m"
echo -e "\e[92mVersion String: ${VERSION_STRING}\e[0m"
echo -e "\e[92mBuild Date....: ${BUILD_DATE}\e[0m"
echo Preparing...
if [[ -d "${CURRENT_DIR}"/.Classes  ]]; then
    echo -e "\e[91m(!) Original Classes source tree appears to have not been restored.\e[0m"
    echo -e "\e[91m    If you think this is in error, run 'make clean' before invoking the build script again.\e[0m"
    echo -e "\e[93mContinuing in 5 seconds...\e[0m"
    sleep 5
    SHA1SUM="$(find "${CURRENT_DIR}"/.Classes -type f -iname '*.uc' -print0 | sort -z | xargs -0 sha1sum | sha1sum | awk '{print $1}')"
else
    SHA1SUM="$(find "${CURRENT_DIR}"/Classes -type f -iname '*.uc' -print0 | sort -z | xargs -0 sha1sum | sha1sum | awk '{print $1}')"
fi
SHA1SUM_OLD="$(cat "${CURRENT_DIR}"/Classes.sha1sum 2>/dev/null)"
if [[ -f "${CURRENT_DIR}"/Classes.sha1sum && "${SHA1SUM_OLD}" = "${SHA1SUM}" ]]; then echo 'Source directory unchanged since last build. Nothing to do. Exiting.' && exit 1; fi
if [[ ${NO_PREPROCESS} -eq 0 ]]; then
    echo Preprocessing...
    if [[ -f "${CURRENT_DIR}"/Classes/.preprocessed ]]; then
        echo -e "\e[91m(!) Classes source tree appears to have already been preprocessed. Skipping...\e[0m"
        echo -e "\e[91m    If you think this is in error, run 'make clean' before invoking the build script again.\e[0m"
    else
        cp -r "${CURRENT_DIR}"/Classes "${CURRENT_DIR}"/.Classes

        OPTS=()
        [[ ${RELEASE_BUILD} -eq 0 ]] && OPTS+=("-D__DEBUG__")

        INC_LINES=0
        if [[ -f "${CURRENT_DIR}/${BASENAME}.inc" ]]; then

            # Test number of lines in output include file
            gpp \
                -n -U "" "" "(" "," ")" "(" ")" "#" "" \
                -M "\n#\w" "\n" " " " " "\n" "" "" \
                +cccs "/*" "*/" +cccs "//" "\n" +cccs "\\\n" "" \
                +s "\"" "\"" "\\" +s "'" "'" "\\" \
                ${OPTS[@]} \
                -D__VERSION__="${VERSION}" \
                -D__BUILDINFO__="${BUILD_INFO}" \
                -D__VERSIONSTRING__="${VERSION_STRING}" \
                -D__BUILDDATE__="${BUILD_DATE}" \
                -D__FILE__="${BASENAME}.inc" \
                -o "${CURRENT_DIR}/.${BASENAME}.inc" \
                "${CURRENT_DIR}/${BASENAME}.inc"

            INC_LINES=$(wc -l "${CURRENT_DIR}/.${BASENAME}.inc" | cut -d' ' -f1)
            rm "${CURRENT_DIR}/.${BASENAME}.inc"

            OPTS+=("--nostdinc")
            OPTS+=("--include ${CURRENT_DIR}/${BASENAME}.inc")
        fi

        for FILE in "${CURRENT_DIR}"/.Classes/*.uc; do

            DEST="${CURRENT_DIR}/Classes/$(basename ${FILE})"

            gpp \
                -n -U "" "" "(" "," ")" "(" ")" "#" "" \
                -M "\n#\w" "\n" " " " " "\n" "" "" \
                +csss "/*" "*/" +csss "//" "\n" +csss "\\\n" "" \
                +s "\"" "\"" "\\" +s "'" "'" "\\" \
                ${OPTS[@]} \
                -D__VERSION__="${VERSION}" \
                -D__BUILDINFO__="${BUILD_INFO}" \
                -D__VERSIONSTRING__="${VERSION_STRING}" \
                -D__BUILDDATE__="${BUILD_DATE}" \
                -D__FILE__="$(basename ${FILE})" \
                -o "${DEST}" \
                "${FILE}"

            # Remove lines occupied by include file if we used one
            if [[ ${INC_LINES} -ne 0 ]]; then
                tail -n +$((${INC_LINES} + 1)) "${DEST}" >"${DEST}.1"
                mv -f "${DEST}.1" "${DEST}"
            fi
        done
        touch "${CURRENT_DIR}"/Classes/.preprocessed
    fi
fi
echo Compiling...
[[ -f "${SYSTEM_DIR}/${BASENAME}.u" ]] && mv -vf "${SYSTEM_DIR}/${BASENAME}.u" "${SYSTEM_DIR}/.${BASENAME}.u.bak"
{
    wine ${UCC} make ini=..\\${BASENAME}\\make.ini 2>/dev/null && echo ${SHA1SUM} > ${CURRENT_DIR}/Classes.sha1sum
} || {
    mv -vf "${SYSTEM_DIR}/.${BASENAME}.u.bak" "${SYSTEM_DIR}/${BASENAME}.u"
    EXIT_STATUS=1
}
restore
exit $EXIT_STATUS
