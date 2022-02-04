#!/usr/bin/env bash
#
# Copyright (c) 2018 The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

export LC_ALL=C.UTF-8

travis_retry docker pull "$DOCKER_NAME_TAG"

export DIR_FUZZ_IN=${TRAVIS_BUILD_DIR}/qa-assets
git clone https://github.com/bitcoin-core/qa-assets ${DIR_FUZZ_IN}
export DIR_FUZZ_IN=${DIR_FUZZ_IN}/fuzz_seed_corpus/

env | grep -E '^(BITCOIN_CONFIG|CCACHE_|WINEDEBUG|LC_ALL|BOOST_TEST_RANDOM|CONFIG_SHELL)' | tee /tmp/env
if [[ $HOST = *-mingw32 ]]; then
  DOCKER_ADMIN="--cap-add SYS_ADMIN"
elif [[ $BITCOIN_CONFIG = *--with-sanitizers=*address* ]]; then # If ran with (ASan + LSan), Docker needs access to ptrace (https://github.com/google/sanitizers/issues/764)
  DOCKER_ADMIN="--cap-add SYS_PTRACE"
fi
DOCKER_ID=$(docker run $DOCKER_ADMIN -idt --mount type=bind,src=$TRAVIS_BUILD_DIR,dst=$TRAVIS_BUILD_DIR --mount type=bind,src=$CCACHE_DIR,dst=$CCACHE_DIR --mount type=bind,src=$PARAMS_DIR,dst=$PARAMS_DIR -w $TRAVIS_BUILD_DIR --env-file /tmp/env $DOCKER_NAME_TAG)

DOCKER_EXEC () {
  docker exec $DOCKER_ID bash -c "cd $PWD && $*"
}

travis_retry DOCKER_EXEC apt-get update
travis_retry DOCKER_EXEC apt-get install --no-install-recommends --no-upgrade -qq $PACKAGES $DOCKER_PACKAGES

