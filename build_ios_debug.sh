#!/bin/zsh

if [[ ${SKIA_OUT} == "" ]]; then
    SKIA_OUT=out/skia
fi

if ! [ -d $SKIA_OUT/ios ]; then
mkdir -p ${SKIA_OUT}/ios
fi

export IPHONEOS_DEPLOYMENT_TARGET=8.0

#ios-arm
echo "Creating out/skia_ios_arm ..."
bin/gn gen out/skia_ios_arm  --args='target_os="ios" target_cpu="arm" is_official_build=true skia_enable_skottie=false skia_use_libpng_decode=false skia_use_libpng_encode=false skia_use_libjpeg_turbo_decode=false skia_use_libjpeg_turbo_encode=false skia_enable_tools=false skia_use_icu=false skia_enable_pdf=false skia_use_dng_sdk=false skia_use_piex=false skia_use_system_libwebp=false skia_use_zlib=false skia_use_expat=false extra_cflags=["-DIPHONEOS_DEPLOYMENT_TARGET=8.0","-DSKIA_DLL","-DGR_TEST_UTILS=0","-miphoneos-version-min=8.0","-w"]'
ninja -C out/skia_ios_arm
echo "build ios_arm success~！"

#ios-arm64
echo "Creating out/skia_ios_arm64 ..."
bin/gn gen out/skia_ios_arm64  --args='target_os="ios" target_cpu="arm64" is_official_build=true skia_enable_skottie=false skia_use_libpng_decode=false skia_use_libpng_encode=false skia_use_libjpeg_turbo_decode=false skia_use_libjpeg_turbo_encode=false skia_enable_tools=false skia_use_icu=false skia_enable_pdf=false skia_use_dng_sdk=false skia_use_piex=false skia_use_system_libwebp=false skia_use_zlib=false skia_use_expat=false extra_cflags=["-DIPHONEOS_DEPLOYMENT_TARGET=8.0","-DSKIA_DLL","-DGR_TEST_UTILS=0","-miphoneos-version-min=8.0","-w"]'
ninja -C out/skia_ios_arm64
echo "build ios_arm64 success~！"

#ios-x64
echo "Creating out/skia_ios_x64 ..."
bin/gn gen out/skia_ios_x64  --args='target_os="ios" target_cpu="x64" is_official_build=true skia_enable_skottie=false skia_use_libpng_decode=false skia_use_libpng_encode=false skia_use_libjpeg_turbo_decode=false skia_use_libjpeg_turbo_encode=false skia_enable_tools=false skia_use_icu=false skia_enable_pdf=false skia_use_dng_sdk=false skia_use_piex=false skia_use_system_libwebp=false skia_use_zlib=false skia_use_expat=false extra_cflags=["-DIPHONEOS_DEPLOYMENT_TARGET=8.0","-DSKIA_DLL","-DGR_TEST_UTILS=0","-miphoneos-version-min=8.0","-w"]'
ninja -C out/skia_ios_x64
echo "build ios_x64 success~！"

rm -f ${SKIA_OUT}/ios/libskia.a
lipo -create out/skia_ios_arm64/libskia.a out/skia_ios_arm/libskia.a out/skia_ios_x64/libskia.a -o ${SKIA_OUT}/ios/libskia.a
echo "lib copied to：${SKIA_OUT}/ios/libskia.a~！"
