#!/bin/sh

NASM=$(toolchain/dependencies/check-host-nasm.sh)

if [ -z "$NASM" ] ; then
	echo build-nasm-host-binary
else
	echo use-nasm-host-binary
fi
