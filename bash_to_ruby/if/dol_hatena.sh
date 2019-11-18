#!/bin/bash

curl http://www.google.co.jp >/dev/null 2>&1

if [ $? = 0 ]; then
  echo "curlは正常終了"
else
  echo "curlは異常終了"
fi