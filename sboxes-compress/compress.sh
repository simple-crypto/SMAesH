#!/usr/bin/env bash

set -e
set -o pipefail
HASH_FILE=$(dirname $SBOX_FILE)/sbox_src_hash

SRC_FILE=./canright_aes_sbox_dual.v

EXPECTED_HASH=$({
	echo $NSHARES &
	git -C compress show-ref HEAD &
	cat $SRC_FILE
} | sha256sum | cut -d ' ' -f 1)

if [ -f $HASH_FILE ] && [ -f $SBOX_FILE ]; then
	OLD_HASH=$(cat $HASH_FILE)
else
	OLD_HASH="OLDhashinvalid"
fi

if [ "$OLD_HASH" != "$EXPECTED_HASH" ]; then
	echo "run compress"
	make RES_FILE=$SBOX_FILE
	echo $EXPECTED_HASH >$HASH_FILE
else
	echo "COMPRESS sbox up-to-date, skipping."
fi
