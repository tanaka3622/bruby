#!/bin/bash

DIR="test"

if [ -d ${DIR} ]; then
  echo "ディレクトリが存在します"
else
  echo "ディレクトリが存在しません"
fi