DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# set up sudo stuff
# TODO
# su $USER;

# packages
(
bash -x $DOTFILES/packages/yaourt_install;
bash -x $DOTFILES/packages/arch_packages;
)

# stow
cd $DOTFILES/stow;
stow *;

# scripts
for SCRIPT in $DOTFILES/scripts/*/configure.sh
do
    if [ -f $SCRIPT -a -x $SCRIPT ]
    then
        $SCRIPT
    fi
done
