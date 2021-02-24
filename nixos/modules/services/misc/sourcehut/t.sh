#!/usr/bin/env bash
f(){
    [[ "$1" =~ \#! ]]
}

g(){
    [ "$1" = \#! ]
}

if f "$1"; then
    echo $?
    echo "if is true"
else
    echo $?
    echo "if is false"
fi

echo

if g "$1"; then
    echo $?
    echo "if is true"
else
    echo $?
    echo "if is false"
fi
