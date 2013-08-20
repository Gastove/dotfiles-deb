#!/bin/bash

# Huh. So this should be a lot simpler than the OSX version. Any installed package is going to be
# handled by apt-get updates, so beyond making sure that anything I've added is Actually Installed,
# it doesn't have to check for upgrades one-by-one.

DOTFILES_DIRECTORY="${HOME}/.dotfiles"
DOTFILES_TARBALL_PATH="https://github.com/gastove/dotfiles-db/tarball/master"
DOTFILES_GIT_REMOTE="https://github.com/gastove/dotfiles-deb"

# Check for the directory; download if needed.
if [[ ! -d ${DOTFILES_DIRECTORY} ]]; then
    printf "$( tput setaf 7)Downloading dotfiles... \033 [m\n"
    mkdir {$DOTFILES_DIRECTORY}
    # Get the tarball, somehow? Figure this out.
    curl -fsSLo ${HOME}/dotfiles.tar.gz ${DOTFILES_TARBALL_PATH}
    # Extract it
    tar -xzf ${HOME}/dotfiles.tar.gz --strip-components 1 -C ${DOTFILES_DIRECTORY}
    # Remove the tarball
    rm -rf ${HOME}/dotfiles.tar.gz
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
    sudo apt-get purge emacs-snapshot-common emacs-snapshot-bin-common emacs-snapshot emacs-snapshot-el emacs-snapshot-gtk emacs23 emacs23-bin-common emacs23-common emacs23-el emacs23-nox emacs23-lucid auctex emacs24 emacs24-bin-common emacs24-common emacs24-common-non-dfsg
fi

# GCC is standard on Debian flavors, so skip checking for now.
# Start with everything fresh and new.
sudo apt-get update
sudo apt-get upgrade -y

apt_install_standards

if dpkg-query -l rvm > /dev/null; then
    printf "Ruby found, moving on"
else
    e_header "Installing RVM, you lucky scamp"
    curl -L https://get.rvm.io | bash -s stable
    e_header "Done with RVM"
fi

if ! is_git_repo; then
    e_header "Initializing git repo"
    git init
    git remote add origin ${DOTFILES_GIT_REMOTE}
    git fetch origin master
fi

if [[ $no_sync ]]; then
    printf "Skipped dotfile sync.\n"
else
    e_header "Syncing dotfiles..."
    git pull --rebase origin master
    git submodule update --recursive --init --quiet
fi

link() {
    # Force create/replace the symlink.
    ln -fs "${DOTFILES_DIRECTORY}/${1}" "${HOME}/${2}"
}

mirrorfiles() {
    # Copy `.gitconfig`.
    # Any global git commands in `~/.bash_profile.local` will be written to
    # `.gitconfig`. This prevents them being committed to the repository.
    rsync -avz --quiet ${DOTFILES_DIRECTORY}/git/gitconfig  ${HOME}/.gitconfig

    # Force remove the vim directory if it's already there.
    if [ -e "${HOME}/.vim" ]; then
        rm -rf "${HOME}/.vim"
    fi

    # Create the necessary symbolic links between the `.dotfiles` and `HOME`
    # directory. The `bash_profile` sources other files directly from the
    # `.dotfiles` repository.
    link "bash/bashrc"        ".bashrc"
    link "bash/bash_aliases"  ".bash_aliases"
    link "bash/inputrc"       ".inputrc"
    link "git/gitattributes"  ".gitattributes"
    link "git/gitignore"      ".gitignore"

    e_success "Dotfiles update complete!"
}

# Ask before potentially overwriting files
seek_confirmation "Warning: This step may overwrite your existing dotfiles."

if is_confirmed; then
    mirrorfiles
    source ${HOME}/.bash_profile
else
    printf "Aborting...\n"
    exit 1
fi
