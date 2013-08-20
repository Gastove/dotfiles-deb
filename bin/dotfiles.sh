#!/bin/bash

# Huh. So this should be a lot simpler than the OSX version. Any installed package is going to be
# handled by apt-get updates, so beyond making sure that anything I've added is Actually Installed,
# it doesn't have to check for upgrades one-by-one.

DOTFILES_DIRECTORY="${HOME}/.dotfiles"
#DOTFILES_TARBALL_PATH -- I have no real idea how to set this. Figure it out?
DOTFILES_GIT_REMOTE="https://github.com/gastove/dotfiles-deb"

# Check for the directory; download if needed.
if [[ ! -d ${DOTFILES_DIRECTORY} ]]; then
    printf "$( tput setaf 7)Downloading dotfiles... \033 [m\n"
    mkdir {$DOTFILES_DIRECTORY}
    # Get the tarball, somehow? Figure this out.
    # curl -fsSLo ${HOME}/dotfiles.tar.gz ${DOTFILES_TARBALL_PATH}
    # Extract it
    # tar -xzf ${HOME}/dotfiles.tar.gz --trip-components 1 -C ${DOTFILES_DIRECTORY}
    # Remove the tarball
    # rm -rf ${HOME}/dotfiles.tar.gz
fi

source ./lib/help
source ./lib/list
source ./lib/utils
source ./lib/apt


# Show help on flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    run_help
    exit
fi

# List additional software

if [[ "$1" == "-l" || "$1" == "--list" ]]; then
    run_list
    exit
fi

# Test for known flags
for opt in $@
do
    case $opt in
        --no-packages) no_packages=true ;;
        --no-sync) no_sync=true ;;
        -*|--*) e_warning "Warning: invalid option $opt" ;;
    esac
done

# Let's get rocking.

# Add an emacs repo
if ! apt_repo_exists 'cassou'; then
    printf "Adding Cassou Repo for Emacs 24 Goodness"
    sudo apt-add-repository ppa:cassou/emacs
fi

# GCC is standard on Debian flavors, so skip checking for now.
# Start with everything fresh and new.
sudo apt-get update
sudo apt-get upgrade -y

apt_install_standards


#  exists



sudo apt-get purge emacs-snapshot-common emacs-snapshot-bin-common emacs-snapshot emacs-snapshot-el emacs-snapshot-gtk emacs23 emacs23-bin-common emacs23-common emacs23-el emacs23-nox emacs23-lucid auctex emacs24 emacs24-bin-common emacs24-common emacs24-common-non-dfsg
