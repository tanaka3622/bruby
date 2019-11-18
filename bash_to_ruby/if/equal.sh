#!/bin/bash

hoge="A"
fuga="A"

if [ $hoge = $fuga ]; then
  echo "文字列は同じです"
else
  echo "文字列は違います"
fi
