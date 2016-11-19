dotfiles
========
Dotfiles for arch linux


Dependencies
============
* curl
* base-devel

Install these with `# pacman -S curl base-devel`.


Instructions
============
Modify `packages/arch_packages` as desired. Run `$ .dotfiles/arch_setup_all.sh`.

[//]: # (
First edit the applications.conf in the root to choose which applications you
want to import configurations for. Then, run `./install` to install the
configurations.)


[Fonts](https://wiki.archlinux.org/index.php/Fonts)
===================================================
Desire to support various character sets may vary.

Some useful tests:
 * [Basic unicode test](http://www.madore.org/~david/misc/unitest/)
 * [UTF-8 test](http://www.fileformat.info/info/unicode/utf8test.htm)
