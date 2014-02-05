# Maintainer: Eric Schulte <schulte.eric@gmail.com>
pkgname=asm-tools
pkgver=20140204
pkgrel=1
pkgdesc="utilities for modifying x86 assembler"
arch=('i686' 'x86_64')
url="https://github.com/eschulte/asm-tools"
license=('GPL')
depends=('bash')
makedepends=('git' 'make' 'sbcl' 'buildapp')
provides=('asm-tools')
source=(git+https://github.com/eschulte/asm-tools.git)
md5sums=('SKIP')

pkgver() {
    cd "$srcdir/$pkgname"
    git describe --long | sed -E 's/([^-]*-g)/r\1/;s/-/./g'; }

build() {
    cd "$srcdir/$pkgname"
    make; }

package() {
    cd "$srcdir/$pkgname"
    make DESTDIR="$pkgdir/" install; }
