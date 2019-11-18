#!/bin/bash

var1=1
var2=2

# >
if [ $var2 -gt $var1 ] ; then
  echo "var2はvar1より大きい"
else
  echo "var2はvar1以下"
fi