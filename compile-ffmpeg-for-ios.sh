#!/bin/sh

export PLATFORM="iPhoneOS"
export MIN_VERSION="5.0"
export MAX_VERSION="6.0"
export DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer
export SDKROOT=$DEVROOT/SDKs/${PLATFORM}${MAX_VERSION}.sdk
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

COMMONFLAGS="-pipe -gdwarf-2 -no-cpp-precomp -isysroot ${SDKROOT} -marm -fPIC"
export LDFLAGS="${COMMONFLAGS} -fPIC"
export CFLAGS="${COMMONFLAGS} -fvisibility=hidden"
export CXXFLAGS="${COMMONFLAGS} -fvisibility=hidden -fvisibility-inlines-hidden"

FFMPEG_LIBS="libavcodec libavdevice libavformat libavutil libswscale"

echo "Building armv7..."

make clean
./configure \
    --cpu=cortex-a8 \
    --extra-cflags="-arch armv7 -miphoneos-version-min=${MIN_VERSION} -mthumb -I${SRCROOT}/rtmpdump/include" \
    --extra-ldflags="-arch armv7 -miphoneos-version-min=${MIN_VERSION} -L${SRCROOT}/rtmpdump/lib -L${SRCROOT}/ios-openssl/lib -lrtmp -lcrypto -lssl" \
    --enable-cross-compile \
    --arch=arm \
    --target-os=darwin \
    --cc=${CC} \
    --sysroot=${SDKROOT} \
    --prefix=installed \
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
    --enable-muxer=flv \
    --enable-demuxer=flv \
    --enable-parser=flv \
    --enable-librtmp \
    --enable-protocol=rtmp \
    --enable-protocol=file \
    --enable-decoder=h264 \
    --enable-decoder=aac \
    --enable-decoder=svq3 \
    --enable-gpl \
    --enable-pic \
    --disable-doc
perl -pi -e 's/HAVE_INLINE_ASM 1/HAVE_INLINE_ASM 0/' config.h
make -j3

mkdir -p build.armv7
for i in ${FFMPEG_LIBS}; do cp ./$i/$i.a ./build.armv7/; done

echo "Building armv7s..."

make clean
./configure \
    --cpu=cortex-a8 \
    --extra-cflags="-arch armv7s -miphoneos-version-min=${MIN_VERSION} -mthumb -I${SRCROOT}/rtmpdump/include" \
    --extra-ldflags="-arch armv7s -miphoneos-version-min=${MIN_VERSION} -L${SRCROOT}/rtmpdump/lib -L${SRCROOT}/ios-openssl/lib -lrtmp -lcrypto -lssl" \
    --enable-cross-compile \
    --arch=arm \
    --target-os=darwin \
    --cc=${CC} \
    --sysroot=${SDKROOT} \
    --prefix=installed \
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
    --enable-muxer=flv \
    --enable-demuxer=flv \
    --enable-parser=flv \
    --enable-librtmp \
    --enable-protocol=rtmp \
    --enable-protocol=file \
    --enable-decoder=h264 \
    --enable-decoder=aac \
    --enable-decoder=svq3 \
    --enable-gpl \
    --enable-pic \
    --disable-doc
perl -pi -e 's/HAVE_INLINE_ASM 1/HAVE_INLINE_ASM 0/' config.h
make -j3

mkdir -p build.armv7s
for i in ${FFMPEG_LIBS}; do cp ./$i/$i.a ./build.armv7s/; done

mkdir -p build.universal
for i in ${FFMPEG_LIBS}; do lipo -create ./build.armv7/$i.a ./build.armv7s/$i.a -output ./build.universal/$i.a; done

for i in ${FFMPEG_LIBS}; do cp ./build.universal/$i.a ./$i/$i.a; done

make install
