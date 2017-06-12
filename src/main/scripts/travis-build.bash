#!/bin/bash
# build, test, and publish maven projects on Travis CI

set -o pipefail

declare Pkg=travis-build-mvn
declare Version=0.3.0

function msg() {
    echo "$Pkg: $*"
}

function err() {
    msg "$*" 1>&2
}

function main() {
    msg "branch is ${TRAVIS_BRANCH}"

    local mvn="mvn --settings .settings.xml -B -V -U -Datomist.enabled=false"

    if [[ $TRAVIS_TAG =~ ^[0-9]+\.[0-9]+\.[0-9]+(-(m|rc)\.[0-9]+)?$ ]]; then
        if ! $mvn build-helper:parse-version versions:set -DnewVersion="$TRAVIS_TAG" versions:commit; then
            err "failed to set project version to $TRAVIS_TAG"
            return 1
        fi
    fi

    if ! $mvn install -Dmaven.javadoc.skip=true; then
        err "maven install failed"
        return 1
    fi

    if [[ $TRAVIS_PULL_REQUEST != false ]]; then
        msg "not deploying pull request"
        return 0
    fi

    if [[ $TRAVIS_BRANCH == master || $TRAVIS_TAG =~ ^[0-9]+\.[0-9]+\.[0-9]+(-(m|rc)\.[0-9]+)?$ ]]; then
        if ! $mvn deploy -DskipTests; then
            err "maven deploy failed"
            return 1
        fi
    fi
}

main "$@" || exit 1
exit 0
