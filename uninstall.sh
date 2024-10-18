
#!/bin/bash
# update all submodules
git submodule update --init --recursive

packages=(`ls -d */ | tr "\n" " " | sed 's/\///g'`)
echo "Installing config for selected packages $packages"
printf '%s\n' "${packages[@]}"
for package in "${packages[@]}"
do 
    echo "Cleaning config for $package"
    stow -D $package
done

