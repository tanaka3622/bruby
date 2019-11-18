#!/bin/bash

var1=1
var2=2

# <
if [ $var1 -lt $var2 ] ; then
  echo "var1はvar2より小さい"
else
  echo "var1はvar2以上"
fi