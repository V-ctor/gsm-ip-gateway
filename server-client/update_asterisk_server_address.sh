#!/bin/sh
find . -maxdepth 1 -type f -not -name "*.sh" -exec sed -i "s/$1/$2/g" {} +