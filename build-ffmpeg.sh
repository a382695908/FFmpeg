#!/bin/bash

###########################################################################
#  Choose your ffmpeg version and your currently-installed iOS SDK version:
#
SDKVERSION="7.0"
FFMPEG_CONFIG=" \
    --disable-bzlib \
    --disable-avresample \
    --disable-decoders \
    --disable-protocols \
    --disable-muxers \
    --disable-demuxers \
    --disable-devices \
    --disable-parsers \
    --disable-encoders \
    --disable-filters \
    --disable-bsfs \
    --disable-avfilter \
    --disable-postproc \
    --disable-swresample \
    --enable-demuxer=mov \
    --enable-demuxer=m4v \
    --enable-muxer=mp4 \
    --enable-muxer=mpegts \
    --enable-protocol=file \
    --enable-protocol=pipelike \
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
#
#
###########################################################################
#
# Don't change anything under this line!
#
###########################################################################

# No need to change this since xcode build will only compile in the
# necessary bits from the libraries we create
ARCHS="armv7 armv7s i386"

DEVELOPER=`xcode-select -print-path`

cd "`dirname \"$0\"`"
REPOROOT="."
ABSREPOROOT=$(pwd)

# Where we'll end up storing things in the end
OUTPUTDIR="${REPOROOT}/../ffmpeg.build"
mkdir -p ${OUTPUTDIR}/include
mkdir -p ${OUTPUTDIR}/lib
mkdir -p ${OUTPUTDIR}/bin


# where we will keep our sources and build from.
SRCDIR="${REPOROOT}"
mkdir -p $SRCDIR
# where we will store intermediary builds
INTERDIR="${REPOROOT}/build"

########################################

cd $SRCDIR

# Exit the script if an error happens
set -e

for ARCH in ${ARCHS}
do
	if [ "${ARCH}" == "i386" ];
	then
		PLATFORM="iPhoneSimulator"
        EXTRA_CONFIG="--arch=i386 --disable-asm --enable-cross-compile --target-os=darwin --cpu=i386"
        EXTRA_CFLAGS="-arch i386"
        EXTRA_LDFLAGS="-I${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk/usr/lib -mfpu=neon"
	else
		PLATFORM="iPhoneOS"
        EXTRA_CONFIG="--arch=arm --target-os=darwin --enable-cross-compile --cpu=cortex-a9"
        EXTRA_CFLAGS="-w -arch ${ARCH} -mfpu=neon"
        EXTRA_LDFLAGS="-mfpu=neon"
	fi

	mkdir -p "${INTERDIR}/${ARCH}"

    make distclean || true

    ./configure --prefix="${INTERDIR}/${ARCH}" $FFMPEG_CONFIG --sysroot="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk" --cc="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang" --as='/usr/local/bin/gas-preprocessor.pl' --extra-cflags="${EXTRA_CFLAGS} -miphoneos-version-min=${SDKVERSION} -I${OUTPUTDIR}/include" --extra-ldflags="-arch ${ARCH} ${EXTRA_LDFLAGS} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk -miphoneos-version-min=${SDKVERSION} -L${OUTPUTDIR}/lib" ${EXTRA_CONFIG} --enable-pic --extra-cxxflags="$CPPFLAGS -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk"

    make -j4 && make install && cp config.h "${INTERDIR}/${ARCH}/include/" && make clean
	 
done

mkdir -p "${INTERDIR}/universal/lib"

cd "${INTERDIR}/armv7/lib"
for file in *.a
do

cd "${ABSREPOROOT}/${INTERDIR}"
xcrun -sdk iphoneos lipo -output universal/lib/$file  -create -arch armv7 armv7/lib/$file -arch armv7s armv7s/lib/$file -arch i386 i386/lib/$file
echo "Universal $file created."

done
cd "$ABSREPOROOT"

cp -a ${INTERDIR}/universal/lib $OUTPUTDIR/
mkdir -p $OUTPUTDIR/include/i386
cp -a ${INTERDIR}/i386/include/* $OUTPUTDIR/include/i386/
mkdir -p $OUTPUTDIR/include/armv7
cp -a ${INTERDIR}/armv7/include/* $OUTPUTDIR/include/armv7/
mkdir -p $OUTPUTDIR/include/armv7s
cp -a ${INTERDIR}/armv7s/include/* $OUTPUTDIR/include/armv7s/

echo "Done."
