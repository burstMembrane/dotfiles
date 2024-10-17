#!/bin/bash
# update all submodules
git submodule update --init --recursive
home_dir_packages=("vim" "git" "zsh" "tmux")
config_dir_packages=("nvim" "kitty")
for package in "${home_dir_packages[@]}"
do 
  if [ -d $package ]; then 
    echo "Installing config for $package"
    echo "stow -t $HOME $package"
  else
    echo "No config for $package"
fi
done

for package in "${config_dir_packages[@]}"
do 
  if [ -d $package ]; then 
    echo "Installing config for $package"
    echo "stow -t $HOME/.config $package"
  else
    echo "No config for $package"
fi
done
