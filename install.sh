#!/bin/bash
# update all submodules
git submodule update --init --recursive
home_dir_packages=("vim" "git" "zsh" "tmux" "nvim")
for package in "${home_dir_packages[@]}"
do 
  if [ -d $package ]; then 
    echo "Installing config for $package"
    echo "stow -t $HOME $package"
  else
    echo "No config for $package"
fi
done

