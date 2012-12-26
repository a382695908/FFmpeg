#!/bin/sh

export DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer
export SDKROOT=$DEVROOT/SDKs/MacOSX10.8.sdk
export CC=$DEVROOT/usr/bin/llvm-gcc
export LD=$DEVROOT/usr/bin/ld
export CPP=$DEVROOT/usr/bin/cpp
export CXX=$DEVROOT/usr/bin/llvm-g++
export AR=$DEVROOT/usr/bin/ar
export LIBTOOL=$DEVROOT/usr/bin/libtool
export NM=$DEVROOT/usr/bin/nm
export CXXCPP=$DEVROOT/usr/bin/cpp
export RANLIB=$DEVROOT/usr/bin/ranlib
export SRCROOT=$HOME/Developer/Together/repo

COMMONFLAGS="-pipe -gdwarf-2 -ggdb -no-cpp-precomp -isysroot ${SDKROOT}"
export LDFLAGS="${COMMONFLAGS} -fPIC"
export CFLAGS="${COMMONFLAGS} -fvisibility=hidden"
export CXXFLAGS="${COMMONFLAGS} -fvisibility=hidden -fvisibility-inlines-hidden"

echo "Building MacOSX..."

make clean && \
./configure \
    --extra-cflags="${CFLAGS}" \
    --extra-ldflags="${LDFLAGS}" \
    --extra-cxxflags="${CXXFLAGS}" \
    --prefix=installed/mac \
    --disable-decoders \
    --disable-protocols \
    --disable-muxers \
    --disable-demuxers \
    --disable-devices \
    --disable-parsers \
    --disable-encoders \
    --disable-filters \
    --disable-bsfs \
    --enable-demuxer=mov \
    --enable-demuxer=m4v \
    --enable-muxer=mp4 \
    --enable-muxer=mpegts \
    --enable-protocol=file \
    --enable-decoder=h264 \
    --enable-decoder=aac \
    --enable-decoder=svq3 \
    --enable-bsf=h264_mp4toannexb \
    --enable-gpl \
    --enable-pic \
    --enable-logging \
    --enable-debug=3 \
    --disable-optimizations \
    --disable-stripping \
    --disable-doc \
&& perl -pi -e 's/HAVE_INLINE_ASM 1/HAVE_INLINE_ASM 0/' config.h \
&& make -j3 \
&& make install

