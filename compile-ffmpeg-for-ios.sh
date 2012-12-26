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

COMMONFLAGS="-pipe -gdwarf-2 -no-cpp-precomp -isysroot ${SDKROOT} -marm"
export LDFLAGS="${COMMONFLAGS}"
export CFLAGS="${COMMONFLAGS} -fvisibility=hidden"

FFMPEG_LIBS="libavcodec libavdevice libavformat libavutil"
FFMPEG_OPTIONS="
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
    --disable-doc \
    --disable-swscale \
    --disable-ffmpeg \
    --disable-ffplay \
    --disable-ffprobe \
    --disable-ffserver \
"

echo "Building armv7..."

make distclean
./configure \
    --cpu=cortex-a8 \
    --extra-cflags="${CFLAGS} -arch armv7 -miphoneos-version-min=${MIN_VERSION} -mthumb" \
    --extra-ldflags="${LDFLAGS} -arch armv7 -miphoneos-version-min=${MIN_VERSION}" \
    --enable-cross-compile \
    --arch=arm \
    --target-os=darwin \
    --cc=${CC} \
    --sysroot=${SDKROOT} \
    ${FFMPEG_OPTIONS} \
    --prefix=build.armv7
make -j4
make install
cp config.h build.armv7/include/

echo "Building armv7s..."

make distclean
./configure \
    --cpu=cortex-a8 \
    --extra-cflags="-arch armv7s -miphoneos-version-min=${MIN_VERSION} -mthumb" \
    --extra-ldflags="-arch armv7s -miphoneos-version-min=${MIN_VERSION}" \
    --enable-cross-compile \
    --arch=arm \
    --target-os=darwin \
    --cc=${CC} \
    --sysroot=${SDKROOT} \
    ${FFMPEG_OPTIONS} \
    --prefix=build.armv7s
make -j4
make install
cp config.h build.armv7s/include/

export PLATFORM="iPhoneSimulator"
export DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer
export SDKROOT=$DEVROOT/SDKs/${PLATFORM}${MAX_VERSION}.sdk
export CC=/usr/bin/clang
export LD=$DEVROOT/usr/bin/ld
export CPP=$DEVROOT/usr/bin/cpp
export CXX=$DEVROOT/usr/bin/llvm-g++
export AR=$DEVROOT/usr/bin/ar
export LIBTOOL=$DEVROOT/usr/bin/libtool
export NM=$DEVROOT/usr/bin/nm
export CXXCPP=$DEVROOT/usr/bin/cpp
export RANLIB=$DEVROOT/usr/bin/ranlib

COMMONFLAGS="-pipe -gdwarf-2 -no-cpp-precomp -m32 -fomit-frame-pointer -isysroot ${SDKROOT}"
export LDFLAGS="${COMMONFLAGS}"
export CFLAGS="${COMMONFLAGS} -fvisibility=hidden"
export ASFLAGS="-arch i386"

echo "Building i386..."

make distclean
./configure \
    --cpu=i386 \
    --extra-cflags="${CFLAGS} -arch i386 -miphoneos-version-min=${MIN_VERSION}" \
    --extra-ldflags="${LDFLAGS} -arch i386 -miphoneos-version-min=${MIN_VERSION}" \
    --enable-cross-compile \
    --arch=x86 \
    --target-os=darwin \
    --cc=${CC} \
    --sysroot=${SDKROOT} \
    ${FFMPEG_OPTIONS} \
    --prefix=build.i386
make -j4
make install
cp config.h build.i386/include/

echo "Making universal libs..."

mkdir -p build.universal/lib
for i in ${FFMPEG_LIBS}
do
    lipo -create ./build.armv7/lib/$i.a ./build.armv7s/lib/$i.a ./build.i386/lib/$i.a \
        -output ./build.universal/lib/$i.a
done

rm config.h


