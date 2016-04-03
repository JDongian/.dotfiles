DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# packages
sudo $DIR/packages/arch_packages;

# stow
cd $DIR/stow;
stow *;

# scripts
for SCRIPT in $DIR/scripts/*/configure.sh
do
    if [ -f $SCRIPT -a -x $SCRIPT ]
    then
        $SCRIPT
    fi
done
