#!/usr/bin/env bash
#
# Build local installs of python-flint's dependencies. This should be run
# before attempting to build python-flint itself.
# The emsdk environment must be activated before running this script.

set -o errexit

# ------------------------------------------------------------------------- #
#                                                                           #
# The build_variables.sh script sets variables specifying the versions to   #
# use for all dependencies and also the PREFIX variable.                    #
#                                                                           #
# ------------------------------------------------------------------------- #

source bin/build_variables.sh

cd $PREFIX
mkdir -p src
cd src

# ------------------------------------------------------------------------- #
#                                                                           #
# Now build all dependencies.                                               #
#                                                                           #
# ------------------------------------------------------------------------- #

# ----------------------------------------------------------------------- #
#                                                                         #
#                            GMP                                          #
#                                                                         #
# ----------------------------------------------------------------------- #

echo
echo --------------------------------------------
echo "           building GMP"
echo --------------------------------------------
echo

# Needed in GitHub Actions because it is blocked from gmplib.org
git clone https://github.com/oscarbenjamin/gmp_mirror.git
cp gmp_mirror/gmp-$GMPVER.tar.xz .

tar xf gmp-$GMPVER.tar.xz
cd gmp-$GMPVER

# Show the output of configfsf.guess
chmod +x configfsf.guess
./configfsf.guess

sed -i '' 's/abilist="standard"/abilist="standard longlong"\nlimb_longlong=longlong/' ./configure
CC_FOR_BUILD=gcc emconfigure ./configure\
    --prefix=$PREFIX\
    --build=i686-pc-linux-gnu\
    --enable-shared=yes\
    --enable-static=no\
    --host=none\
    --disable-assembly\
    --with-readline=no\
    --enable-fft=yes\
    --disable-cxx\
    --enable-alloca=malloc-notreentrant\
    --disable-pthread\
    CFLAGS="-O3 -Wall -fPIC"\
    ABI=longlong
emmake make -j2
emmake make install
cd ..

# ------------------------------------------------------------------------- #
#                                                                           #
#                              MPFR                                         #
#                                                                           #
# ------------------------------------------------------------------------- #


echo
echo --------------------------------------------
echo "           building MPFR"
echo --------------------------------------------
echo

curl -O https://ftp.gnu.org/gnu/mpfr/mpfr-$MPFRVER.tar.gz
tar xf mpfr-$MPFRVER.tar.gz
cd mpfr-$MPFRVER
CC_FOR_BUILD=gcc ABI=long emconfigure ./configure\
    --prefix=$PREFIX\
    --with-gmp=$PREFIX\
    --enable-shared=yes\
    --enable-static=no\
    --build=i686-pc-linux-gnu\
    --host=none\
    CFLAGS="-O3 -Wall -fPIC"
emmake make -j2
emmake make install
cd ..

# ------------------------------------------------------------------------- #
#                                                                           #
#                              FLINT                                        #
#                                                                           #
# ------------------------------------------------------------------------- #

echo
echo --------------------------------------------
echo "           building Flint"
echo --------------------------------------------
echo

curl -O -L https://github.com/flintlib/flint/releases/download/v$FLINTVER/flint-$FLINTVER.tar.gz
tar xf flint-$FLINTVER.tar.gz
cd flint-$FLINTVER
./bootstrap.sh
CC_FOR_BUILD=gcc emconfigure ./configure\
    --prefix=$PREFIX\
    --with-gmp=$PREFIX\
    --with-mpfr=$PREFIX\
    --build=i686-pc-linux-gnu\
    --host=none\
    --disable-static\
    CFLAGS="-O3 -fPIC"\
    CPPFLAGS="-O3 -fPIC"
emmake make -j2
emmake make install
cd ..

# ------------------------------------------------------------------------- #
#                                                                           #
#                              Done!                                        #
#                                                                           #
# ------------------------------------------------------------------------- #

echo
echo -----------------------------------------------------------------------
echo
echo Build dependencies for python-flint compiled as shared libraries in:
echo $PREFIX
echo
echo Versions:
echo GMP: $GMPVER
echo MPFR: $MPFRVER
echo Flint: $FLINTVER
echo
echo -----------------------------------------------------------------------
echo
