#!/bin/sh

CONFIGURE_FLAGS=" \
    --enable-cross-compile \
    --disable-debug \
    --disable-ffmpeg \
    --disable-ffplay \
    --disable-ffprobe \
    --disable-ffserver \
    --disable-doc \
    --disable-encoders \
    --disable-muxers \
    --disable-bsfs \
    --disable-devices \
    --disable-filters \
    --disable-bzlib \
    --disable-avresample \
    --disable-decoders \
    --disable-protocols \
    --disable-demuxers \
    --disable-parsers \
    --disable-avfilter \
    --disable-postproc \
    --disable-swresample \
    --disable-swscale \
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
"

ARCHS="armv7 arm64 i386 x86_64"

# directories
SOURCE="."
FAT="fat"

SCRATCH="scratch"
# must be an absolute path
THIN=`pwd`/"thin"

COMPILE="y"
LIPO="y"

if [ "$*" ]
then
	if [ "$*" = "lipo" ]
	then
		# skip compile
		COMPILE=
	else
		ARCHS="$*"
		if [ $# -eq 1 ]
		then
			# skip lipo
			LIPO=
		fi
	fi
fi

set -e
make distclean || true

if [ "$COMPILE" ]
then
	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="iPhoneSimulator"
		    CPU=
		    if [ "$ARCH" = "x86_64" ]
		    then
		    	SIMULATOR="-mios-simulator-version-min=7.0"
		    else
		    	SIMULATOR="-mios-simulator-version-min=5.0"
		    fi
		else
		    PLATFORM="iPhoneOS"
		    if [ $ARCH = "armv7s" ]
		    then
		    	CPU="--cpu=swift"
		    else
		    	CPU=
		    fi
            if [ $ARCH = "arm64" ]
            then
                DISABLE_ASM="--disable-asm"
            else
                DISABLE_ASM=
            fi
		    SIMULATOR=
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang"
		CFLAGS="-arch $ARCH $SIMULATOR"
		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"

		$CWD/$SOURCE/configure \
		    --target-os=darwin \
		    --arch=$ARCH \
		    --cc="$CC" \
		    $CONFIGURE_FLAGS \
		    --extra-cflags="$CFLAGS" \
		    --extra-cxxflags="$CXXFLAGS" \
		    --extra-ldflags="$LDFLAGS" \
		    $CPU \
            $DISABLE_ASM \
		    --prefix="$THIN/$ARCH"

		make -j3 install
		cd $CWD
	done
fi

if [ "$LIPO" ]
then
	echo "building fat binaries..."
	mkdir -p $FAT/lib
	set - $ARCHS
	CWD=`pwd`
	cd $THIN/$1/lib
	for LIB in *.a
	do
		cd $CWD
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB
	done

	cd $CWD
	cp -rf $THIN/$1/include $FAT
fi

echo "Copying build results to main repo..."
OUTPUTDIR="../FFmpeg.build"

echo cp -a $FAT/lib/* $OUTPUTDIR/lib/
cp -a $FAT/lib/* $OUTPUTDIR/lib/

for ARCH in $ARCHS
do
    mkdir -p $OUTPUTDIR/include/$ARCH
    echo cp -a ${THIN}/$ARCH/include/* $OUTPUTDIR/include/$ARCH/
    cp -a ${THIN}/$ARCH/include/* $OUTPUTDIR/include/$ARCH/
    echo cp -a ${SCRATCH}/$ARCH/config.h $OUTPUTDIR/include/$ARCH/
    cp -a ${SCRATCH}/$ARCH/config.h $OUTPUTDIR/include/$ARCH/
done

