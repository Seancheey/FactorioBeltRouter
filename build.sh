#!/bin/bash
version=$(cat info.json | grep '"version"' | sed s/'^\ *"version": "'// | sed s/'",'//)
name=$(cat info.json | grep '"name"' | sed s/'^\ *"name": "'// | sed s/'",'//)
file="${name}_${version}.zip"
echo building "${file}"
zip -r "${file}" ./ -x "*.png" -x "demo/*" -x ".git/*" -x ".idea/*" -x "*.iml" -x "*.zip"
