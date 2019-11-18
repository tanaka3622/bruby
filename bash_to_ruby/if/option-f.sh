#!/bin/bash

LOCK_FILE="lock"

if [ -f ${LOCK_FILE} ]; then
  echo "ファイルが存在します"
else
  echo "ファイルが存在しません"
fi