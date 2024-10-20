#!/bin/bash
# update all submodules
git submodule update --init --recursive

packages=(`ls -d */ | tr "\n" " " | sed 's/\///g'`)
echo "Installing config for selected packages $packages"
printf '%s\n' "${packages[@]}"
for package in "${packages[@]}"
do 
  if [ -d $package ]; then 
    echo "Installing config for $package"
    stow $package --dotfiles -t $HOME
  else
    echo "No config for $package"
fi
done

