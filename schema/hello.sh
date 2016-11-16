#!/bin/bash

function hello() {
    echo "hello" "$@"
}

if [[ "$BASH_SOURCE" == "$0" ]]
then
    hello "$@"
fi
