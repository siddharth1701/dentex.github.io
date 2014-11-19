#!/bin/bash

function config {
echo "==============================================================="
echo -e "\n ==> configuring ndk...\n"
# -> set the NDK variable below
echo "==============================================================="

# config ndk
export NDK=${HOME}/Scaricati/android-ndk/android-ndk-r8e-linux-x86
SYSROOT=$NDK/platforms/android-14/arch-arm
TOOLCHAIN=`echo $NDK/toolchains/arm-linux-androideabi-4.7/prebuilt/linux-x86`
export PATH=$TOOLCHAIN/bin:$PATH

# FFmpeg version in use
FFMPEG="ffmpeg-2.4.3"

#present dir
BASE_DIR=`pwd`

#config arm build
BUILD_DIRarm="build_arm"
PREFIXarm=$BASE_DIR/$BUILD_DIRarm

BUILD_DIRarm_nonPIE="build_arm_nonPIE"
PREFIXarm_nonPIE=$BASE_DIR/$BUILD_DIRarm_nonPIE

#config arm non NEON build
BUILD_DIRarm_nonNEON="build_arm_nonNEON"
PREFIXarm_nonNEON=$BASE_DIR/$BUILD_DIRarm_nonNEON

BUILD_DIRarm_nonNEON_nonPIE="build_arm_nonNEON_nonPIE"
PREFIXarm_nonNEON_nonPIE=$BASE_DIR/$BUILD_DIRarm_nonNEON_nonPIE

#config x86 build
BUILD_DIRx86="build_x86"
PREFIXx86=$BASE_DIR/$BUILD_DIRx86

BUILD_DIRx86_nonPIE="build_x86_nonPIE"
PREFIXx86_nonPIE=$BASE_DIR/$BUILD_DIRx86_nonPIE

PATH=$PATH:$NDK
TOOLCHAIN=$BASE_DIR/toolchain_x86
$NDK/build/tools/make-standalone-toolchain.sh --toolchain=x86-4.7 --arch=x86 --system=linux-x86 --platform=android-14 --install-dir=$TOOLCHAIN

#non-PIE compilation flags for arm
CFLAGS='-O3 -Wall -pipe -fasm'
LDFLAGS='' #empty

#PIE compilation flags for arm
CFLAGS_PIE='-O3 -Wall -pipe -fasm -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fno-strict-overflow -fstack-protector-all'
LDFLAGS_PIE='-Wl,-z,relro -Wl,-z,now -pie'

#non-PIE compilation flags for x86
CFLAGSx86='-std=c99 -O3 -Wall -pipe -DANDROID -DNDEBUG -march=atom -msse3 -ffast-math -mfpmath=sse' 
LDFLAGSx86='-lm -lz -Wl,--no-undefined -Wl,-z,noexecstack'

#PIE compilation flags for x86
CFLAGS_PIEx86='-std=c99 -DANDROID -DNDEBUG -march=atom -msse3 -ffast-math -mfpmath=sse -O3 -Wall -pipe -fasm -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fno-strict-overflow -fstack-protector-all'
LDFLAGS_PIEx86='-lm -lz -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -pie'

}

function extract {
echo "==============================================================="
echo -e "\n ==> extracting archives...\n"
echo "==============================================================="

tar xjf $FFMPEG.tar.bz2
tar xjf liblame.tar.bz2
}

function build_lame {
echo "==============================================================="
echo -e "\n ==> building lame...\n"
# lame built based on content from 
# https://github.com/intervigilium/liblame
echo "==============================================================="

cd liblame
$NDK/ndk-build

# copy libmp3lame files into android-ndk appropriate folders
# to let the ffmpeg configure script find them

cp -vrn jni/lame $SYSROOT/usr/include
cp -vn libs/armeabi-v7a/liblame.so $SYSROOT/usr/lib/libmp3lame.so

#TODO check
cp -vrn jni/lame $SYSROOTx86/usr/include
cp -vn libs/x86/liblame.so $SYSROOTx86/usr/lib/libmp3lame.so

cd ..
}

function build_arm {
echo "==============================================================="
echo -e "\n ==> building FFmpeg for ARM $1 ...\n"
echo "==============================================================="
cd $FFMPEG

FLAGS="--target-os=linux --cross-prefix=arm-linux-androideabi- --arch=arm --enable-pic\
	--sysroot=$SYSROOT \
	--enable-small \
	--disable-ffplay --disable-ffprobe --disable-ffserver \
	--disable-doc --disable-htmlpages --disable-manpages --disable-podpages --disable-txtpages \
	--enable-libmp3lame"

EXTRA_CFLAGS="-march=armv7-a -mfpu=neon -mfloat-abi=softfp -mvectorize-with-neon-quad"

if [ "$1" = "PIE" ]; then
    PREFIX_IN_USE=$PREFIXarm
    CFLAGS_IN_USE=$CFLAGS_PIE
    LDFLAGS_IN_USE=$LDFLAGS_PIE
else
    PREFIX_IN_USE=$PREFIXarm_nonPIE
    CFLAGS_IN_USE=$CFLAGS
    LDFLAGS_IN_USE=$LDFLAGS
fi

rm -rf $PREFIX_IN_USE
mkdir -p $PREFIX_IN_USE

echo $FLAGS --prefix=$PREFIX_IN_USE --extra-cflags="$CFLAGS_IN_USE $EXTRA_CFLAGS" --extra-ldflags="$LDFLAGS_IN_USE" > $PREFIX_IN_USE/info.txt
./configure $FLAGS --prefix=$PREFIX_IN_USE --extra-cflags="$CFLAGS_IN_USE $EXTRA_CFLAGS" --extra-ldflags="$LDFLAGS_IN_USE" | tee $PREFIX_IN_USE/configuration.txt
[ $PIPESTATUS == 0 ] || exit 1

make clean
make -j4 || exit 1
make prefix=$PREFIX_IN_USE install || exit 1

cd ..
}

function build_arm_nonNEON {
echo "==============================================================="
echo -e "\n ==> building FFmpeg for ARM (NEON disabled) $1 ...\n"
echo "==============================================================="
cd $FFMPEG

FLAGS="--target-os=linux --cross-prefix=arm-linux-androideabi- --arch=arm --enable-pic --disable-neon\
	--sysroot=$SYSROOT \
	--enable-small \
	--disable-ffplay --disable-ffprobe --disable-ffserver \
	--disable-doc --disable-htmlpages --disable-manpages --disable-podpages --disable-txtpages \
	--enable-libmp3lame"

EXTRA_CFLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -I$PREFIXarm_nonNEON/include -DANDROID"  # nonNEON version
# thanks to Jernej (Mavrik) from #ffmpeg on freenode

if [ "$1" = "PIE" ]; then
    PREFIX_IN_USE=$PREFIXarm_nonNEON
    CFLAGS_IN_USE=$CFLAGS_PIE
    LDFLAGS_IN_USE=$LDFLAGS_PIE
else
    PREFIX_IN_USE=$PREFIXarm_nonNEON_nonPIE
    CFLAGS_IN_USE=$CFLAGS
    LDFLAGS_IN_USE=$LDFLAGS
fi

rm -rf $PREFIX_IN_USE
mkdir -p $PREFIX_IN_USE

echo $FLAGS --prefix=$PREFIX_IN_USE --extra-cflags="$CFLAGS_IN_USE $EXTRA_CFLAGS" --extra-ldflags="$LDFLAGS_IN_USE" > $PREFIX_IN_USE/info.txt
./configure $FLAGS --prefix=$PREFIX_IN_USE --extra-cflags="$CFLAGS_IN_USE $EXTRA_CFLAGS" --extra-ldflags="$LDFLAGS_IN_USE" | tee $PREFIX_IN_USE/configuration.txt
[ $PIPESTATUS == 0 ] || exit 1

make clean
make -j4 || exit 1
make prefix=$PREFIX_IN_USE install || exit 1

cd ..
}

function build_x86 {
echo "==============================================================="
echo -e "\n ==> building FFmpeg for x86 $1 ...\n"
echo "==============================================================="

cd $FFMPEG

export PATH=$TOOLCHAIN/bin:$PATH
export CC="ccache i686-linux-android-gcc-4.7"
export LD=i686-linux-android-ld
export AR=i686-linux-android-ar

cp -rn ../liblame/jni/lame $TOOLCHAIN/sysroot/usr/include
cp -n ../liblame/libs/x86/liblame.so $TOOLCHAIN/sysroot/usr/lib/libmp3lame.so

if [ "$1" = "PIE" ]; then
    PREFIX_IN_USE=$PREFIXx86
    CFLAGS_IN_USE=$CFLAGS_PIEx86
    LDFLAGS_IN_USE=$LDFLAGS_PIEx86
else
    PREFIX_IN_USE=$PREFIXx86_nonPIE
    CFLAGS_IN_USE=$CFLAGSx86
    LDFLAGS_IN_USE=$LDFLAGSx86
fi

rm -rf $PREFIX_IN_USE
mkdir -p $PREFIX_IN_USE

FEATURES="--disable-demuxer=sbg --disable-demuxer=dts --disable-parser=dca --disable-decoder=dca --disable-decoder=svq3 \
\
--enable-libmp3lame --disable-devices --disable-filters --disable-protocols --enable-protocol=file"

./configure --target-os=linux --arch=x86 --cpu=i686 --cross-prefix=i686-linux-android- --enable-cross-compile $FEATURES --disable-symver --disable-doc --disable-htmlpages --disable-manpages --disable-podpages --disable-txtpages --disable-ffplay --disable-ffprobe --disable-ffserver --disable-amd3dnow --disable-amd3dnowext --disable-asm --enable-yasm --enable-pic --prefix=$PREFIX_IN_USE --extra-cflags="$CFLAGS_IN_USE" --extra-ldflags="$LDFLAGS_IN_USE" | tee $PREFIX_IN_USE/configuration.txt

make clean
make || exit 1
make install || exit 1

cd ..
}

function copy {
echo "==============================================================="
echo -e "\n ==> copying and renaming builds...\n"
echo "==============================================================="

mkdir $BASE_DIR/builds_LGPL

cp -v $BUILD_DIRarm/bin/ffmpeg 		builds_LGPL/ffmpeg_armv7a
cp -v $BUILD_DIRarm_nonNEON/bin/ffmpeg 	builds_LGPL/ffmpeg_armv7a_nonNEON
cp -v $BUILD_DIRx86/bin/ffmpeg 		builds_LGPL/ffmpeg_x86
cp -v $BUILD_DIRarm_nonPIE/bin/ffmpeg 		builds_LGPL/ffmpeg_armv7a_nonPIE
cp -v $BUILD_DIRarm_nonNEON_nonPIE/bin/ffmpeg 	builds_LGPL/ffmpeg_armv7a_nonNEON_nonPIE
cp -v $BUILD_DIRx86_nonPIE/bin/ffmpeg 		builds_LGPL/ffmpeg_x86_nonPIE
}

function clean {
echo "==============================================================="
echo -e "\n ==> cleaning...\n"
echo "==============================================================="
rm -rf liblame
rm -rf $FFMPEG
rm -rf $BUILD_DIRarm
rm -rf $BUILD_DIRarm_nonNEON
rm -rf $BUILD_DIRx86
rm -rf $BUILD_DIRarm_nonPIE
rm -rf $BUILD_DIRarm_nonNEON_nonPIE
rm -rf $BUILD_DIRx86_nonPIE
rm -rf $TOOLCHAIN
}

#===============================================================

config
extract
build_lame

build_arm PIE
build_arm_nonNEON PIE
build_x86 PIE

build_arm
build_arm_nonNEON
build_x86

copy
clean
#===============================================================
