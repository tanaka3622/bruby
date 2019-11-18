#!/bin/bash

hoge=true

if [ ! $hoge ]; then
  echo "こっちにはこない"
else
  echo "こっちになる"
fi