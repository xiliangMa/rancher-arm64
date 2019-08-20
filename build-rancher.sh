#!/bin/bash

source $(dirname $0)/scripts/common
source $(dirname $0)/scripts/version

ROOT_DIR=$(cd $(dirname $0); pwd)

echo ${ROOT_DIR}

[ ! -d dist ] && mkdir dist
[ ! -d bin ] && mkdir bin
[ ! -d rancher-repos ] && mkdir rancher-repos
[ ! -d .states ] && mkdir .states

cd rancher-repos

git_apply() {
    (
        cd $1
        tag="$2-rancher-${CO_BRANCH}"
        if [ -n "$3" ]; then
            tag="$3"
        fi
        log_info "tag: ${tag}"
        git tag -d "${tag}" || true
        if [ -f ${ROOT_DIR}/patch/$1.diff ]; then
            git apply ${ROOT_DIR}/patch/$1.diff
            git add .
            git commit -m "patch for rancher ${CO_BRANCH}"
        fi
        git tag -a "${tag}" -m "for rancher ${CO_BRANCH}"
    )
}

re_tag() {
    (
        cd $1
        tag="${RANCHER_TAG}${RR_SUFFIX}"
        log_info "tag: ${tag}"
        git tag -d "${tag}" || true
        git tag -a "${tag}" -m "for rancher ${CO_BRANCH}"
    )
}

check-skip() {
    if test -f "${ROOT_DIR}/.states/$1-${CO_BRANCH}-done"; then
        log_info "$1 was built"
        return 0
    else
        log_info "building $1"
        return 1
    fi
}

mark-done() {
    touch ${ROOT_DIR}/.states/$1-${CO_BRANCH}-done
}

export REPO=xiliangma
export ARCH=arm64
export DAPPER_MODE=bind


build-rancher() {
#    if check-skip rancher ; then return 0; fi

    # git_ensure https://github.com/rancher/rancher.git
    # reset rancher "${RANCHER_TAG}"
    # log_info patching
    # git_apply rancher "${RANCHER_TAG}" "${RANCHER_TAG}${RR_SUFFIX}"
     
    re_tag rancher

    log_info build
    (
        cd rancher
        make build && 
		make package 
        cp bin/* ${ROOT_DIR}/bin/
        # docker push ${REPO}/rancher:${RANCHER_TAG}${RR_SUFFIX} \
        # && docker push ${REPO}/rancher-agent:${RANCHER_TAG}${RR_SUFFIX} 
    ) && mark-done rancher
}


log_info "<= building rancher =>"
build-rancher
