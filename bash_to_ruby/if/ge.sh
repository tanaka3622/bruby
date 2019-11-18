#!/bin/bash

var1=2
var2=2

# >=
if [ $var2 -ge $var1 ] ; then
  echo "var2はvar1以上"
else
  echo "var2はvar1より小さい"
fi