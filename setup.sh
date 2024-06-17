#!/bin/bash


#install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

source "~/.zshrc"

brew install asdf

echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ${ZDOTDIR:-~}/.zshrc


#install libyaml
brew install libyaml

brew install tmux
brew install overmind
brew install glib
brew install vips


asdf plugin add ruby

asdf install ruby 2.7.8
asdf global ruby 2.7.8


brew install postgresql
brew services start postgresql
/opt/homebrew/bin/createuser -s postgres
brew install postgis


asdf plugin add nodejs
asdf install nodejs 16.18.1
asdf global nodejs 16.18.1

source "~/.zshrc"

npm install -g yarn

echo "export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES" >> ~/.zshrc


#github
brew install gh
gh auth login


cd ~
mkdir rails
cd rails
git clone https://github.com/Statvis/statvis.git .
bundle update --bundler
bundle config build.ovirt-engine-sdk --with-cflags="-Wno-error=incompatible-function-pointer-types -Wno-error=implicit-function-declaration"
source "~/.zshrc"

cd ~/rails/statvis
# Update to the latest Rubygems version
gem update --system

bundle install




