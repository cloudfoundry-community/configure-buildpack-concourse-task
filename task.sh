#!/bin/bash

set -e

WORKDIR=$(mktemp -d -t 'custom.XXXX'); CLEANDIR=$(mktemp -d -t 'upstream.XXXX')
BUILDPACK=$(basename $(ls ${BUILDPACK_ZIP_GLOB}))
unzip -qq ${BUILDPACK_ZIP_GLOB} -d ${WORKDIR}
cp -r ${WORKDIR}/* ${CLEANDIR}

pushd ${WORKDIR} > /dev/null

replace() {
    find "$(dirname ${1})" -name "$(basename ${1})" | xargs sed -ie "s|${2}|${3}|g"
}

delete() {
    find "$(dirname ${1})" -name "$(basename ${1})" | xargs sed -ie "/${2}/d"
}

for row in $(echo "${PATCHES}" | jq -r '.[] | @base64'); do
    _jq() { echo ${row} | base64 --decode | jq -r "${1}"; }

    if  [ "$(_jq '.replace')" != "null" ]; then
        replace $(_jq '.file') "$(_jq '.search')" "$(_jq '.replace')"
    elif [ "$(_jq '.delete')" != "null" ]; then
        delete $(_jq '.file') "$(_jq '.delete | join("\\|")')"
    fi
done

rm -f config/*.ymle

set +e; diff -u -r ${CLEANDIR} ${WORKDIR}; set -e

zip -qq -r custom-buildpack/custom-${BUILDPACK} *
