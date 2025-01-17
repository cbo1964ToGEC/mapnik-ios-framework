
LIBRARY = libmapnik.a

XCODE_DEVELOPER = $(shell xcode-select --print-path)
IOS_PLATFORM ?= iPhoneOS

# Pick latest SDK in the directory
IOS_PLATFORM_DEVELOPER = ${XCODE_DEVELOPER}/Platforms/${IOS_PLATFORM}.platform/Developer
IOS_SDK = ${IOS_PLATFORM_DEVELOPER}/SDKs/$(shell ls ${IOS_PLATFORM_DEVELOPER}/SDKs | sort -r | head -n1)

all: update lib/libmapnik.a
lib/libmapnik.a: build_arches
	mkdir -p lib
	mkdir -p include

	# Copy includes
	cp -R build/armv7/include/freetype2 include
	cp -R build/armv7/include/mapnik include
	cp -R build/armv7/include/boost include
	cp -R build/armv7/include/unicode include
	cp -R build/armv7/include/cairomm-1.0/cairomm include
	cp -R build/armv7/include/cairomm-1.0/cairomm include
	cp -R build/armv7/include/sigc++-2.0/sigc++ include
	cp libsigc++/sigc++config.h include/
	cp build/armv7/include/cairo/*.h include/
	cp -R build/armv7/include/fontconfig include/
	cp build/armv7/include/ft2build.h include
	cp build/armv7/include/proj_api.h include

	# Make fat libraries for all architectures
	for file in build/armv7/lib/*.a; \
		do name=`basename $$file .a`; \
		${IOS_PLATFORM_DEVELOPER}/usr/bin/lipo -create \
			-arch armv7 build/armv7/lib/$$name.a \
			-arch armv7s build/armv7s/lib/$$name.a \
			-arch i386 build/i386/lib/$$name.a \
			-output lib/$$name.a \
		; \
		done;
	echo "Making libmapnik or something"

update:
	git submodule init
	git submodule update
	-patch -Np0 < pixman.patch

# Build separate architectures
build_arches:
	${MAKE} arch ARCH=armv7 IOS_PLATFORM=iPhoneOS
	${MAKE} arch ARCH=armv7s IOS_PLATFORM=iPhoneOS
	${MAKE} arch ARCH=i386 IOS_PLATFORM=iPhoneSimulator

PREFIX = ${CURDIR}/build/${ARCH}
LIBDIR = ${PREFIX}/lib
INCLUDEDIR = ${PREFIX}/include

CXX = ${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
CC = ${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
CFLAGS = -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH}
CXXFLAGS = -stdlib=libc++ -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH}
LDFLAGS = -stdlib=libc++ -isysroot ${IOS_SDK} -L${LIBDIR} -L${IOS_SDK}/usr/lib -arch ${ARCH}

PIXMAN_CFLAGS_armv7 = $(CFLAGS)
PIXMAN_CFLAGS_armv7s = $(CFLAGS)
PIXMAN_CFLAGS_i386 = $(CFLAGS) -DPIXMAN_NO_TLS
PIXMAN_CXXFLAGS_armv7 = $(CXXFLAGS)
PIXMAN_CXXFLAGS_armv7s = $(CXXFLAGS)
PIXMAN_CXXFLAGS_i386 = $(CXXFLAGS) -DPIXMAN_NO_TLS

arch: ${LIBDIR}/libmapnik.a
	# Making libmapnik

${LIBDIR}/libmapnik.a: ${LIBDIR}/libpng.a ${LIBDIR}/libproj.a ${LIBDIR}/libtiff.a ${LIBDIR}/libjpeg.a ${LIBDIR}/libicuuc.a ${LIBDIR}/libboost_system.a ${LIBDIR}/libcairo.a ${LIBDIR}/libfreetype.a ${LIBDIR}/libcairomm-1.0.a
	# Building architecture: ${ARCH}
	cd mapnik && ./configure CXX=${CXX} CC=${CC} \
		CUSTOM_CFLAGS="${CFLAGS} -I${IOS_SDK}/usr/include/libxml2" \
		CUSTOM_CXXFLAGS="${CXXFLAGS} -DUCHAR_TYPE=uint16_t -I${IOS_SDK}/usr/include/libxml2" \
		CUSTOM_LDFLAGS="${LDFLAGS}" \
		FREETYPE_CONFIG=${PREFIX}/bin/freetype-config XML2_CONFIG=/bin/false \
		{LTDL_INCLUDES,OCCI_INCLUDES,SQLITE_INCLUDES,RASTERLITE_INCLUDES}=. \
		{BOOST_PYTHON_LIB,LTDL_LIBS,OCCI_LIBS,SQLITE_LIBS,RASTERLITE_LIBS}=. \
		BOOST_INCLUDES=${PREFIX}/include \
		BOOST_LIBS=${PREFIX}/lib \
		ICU_INCLUDES=${PREFIX}/include \
		ICU_LIBS=${PREFIX}/lib \
		PROJ_INCLUDES=${PREFIX}/include \
		PROJ_LIBS=${PREFIX}/lib \
		PNG_INCLUDES=${PREFIX}/include \
		PNG_LIBS=${PREFIX}/lib \
		CAIRO_INCLUDES=${PREFIX} \
		CAIRO_LIBS=${PREFIX} \
		JPEG_INCLUDES=${PREFIX}/include \
		JPEG_LIBS=${PREFIX}/lib \
		TIFF_INCLUDES=${PREFIX}/include \
		TIFF_LIBS=${PREFIX}/lib \
		INPUT_PLUGINS=shape \
		BINDINGS=none \
		LINKING=static \
		DEMO=no \
		RUNTIME_LINK=static \
		PREFIX=${PREFIX} && make clean install


# LibPNG
${LIBDIR}/libpng.a:
	cd libpng && env CXX=${CXX} CC=${CC} CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --disable-shared --prefix=${PREFIX} && ${MAKE} clean install

# LibProj
${LIBDIR}/libproj.a:
	cd libproj && env CXX=${CXX} CC=${CC} CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --disable-shared --prefix=${PREFIX} && ${MAKE} clean install

# LibTiff
${LIBDIR}/libtiff.a:
	cd libtiff && env CXX=${CXX} CC=${CC} CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --disable-shared --prefix=${PREFIX} && ${MAKE} clean install

# LibJpeg
${LIBDIR}/libjpeg.a:
	cd libjpeg && env CXX=${CXX} CC=${CC} CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --disable-shared --prefix=${PREFIX} && ${MAKE} clean install

# LibIcu
libicu_host/config/icucross.mk:
	cd libicu_host && ./configure && ${MAKE}

${LIBDIR}/libicuuc.a: libicu_host/config/icucross.mk
	touch ${CURDIR}/license.html
	cd libicu && env CXX=${CXX} CC=${CC} CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS} -std=c++11 -I${CURDIR}/libicu/tools/tzcode -DUCHAR_TYPE=uint16_t" LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --disable-shared --enable-static --prefix=${PREFIX} --with-cross-build=${CURDIR}/libicu_host && ${MAKE} clean install

# Boost
${LIBDIR}/libboost_system.a: ${LIBDIR}/libicuuc.a
	rm -rf boost-build boost-stage
	cd boost && ./bootstrap.sh --with-libraries=thread,signals,filesystem,regex,system,date_time
	cd boost && git checkout tools/build/v2/user-config.jam
	echo "using darwin : iphone \n \
		: ${CXX} -miphoneos-version-min=5.0 -fvisibility=hidden -fvisibility-inlines-hidden ${CXXFLAGS} -I${INCLUDEDIR} -L${LIBDIR} \n \
		: <architecture>arm <target-os>iphone \n \
		;" >> boost/tools/build/v2/user-config.jam
	cd boost && ./bjam -a --build-dir=boost-build --stagedir=boost-stage --prefix=${PREFIX} toolset=darwin architecture=arm target-os=iphone  define=_LITTLE_ENDIAN link=static install

# FreeType
${LIBDIR}/libfreetype.a:
	cd freetype && ./autogen.sh && env CXX=${CXX} CC=${CC} CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --disable-shared --prefix=${PREFIX} && ${MAKE} clean install

# Pixman
${LIBDIR}/libpixman-1.a:
	cd pixman &&  ./autogen.sh && env PNG_CFLAGS="-I${INCLUDEDIR}" PNG_LIBS="-L${LIBDIR} -lpng" \
		CXX=${CXX} CC=${CC} CFLAGS="${PIXMAN_CFLAGS_$(ARCH)}" CXXFLAGS="${PIXMAN_CXXFLAGS_$(ARCH)}" \
		LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --disable-shared --prefix=${PREFIX} && make install

# Cairo
${LIBDIR}/libcairo.a: ${LIBDIR}/libpixman-1.a ${LIBDIR}/libpng.a ${LIBDIR}/libfreetype.a ${LIBDIR}/libfontconfig.a
	env NOCONFIGURE=1 cairo/autogen.sh

	-patch -Np0 < cairo.patch

	cd cairo && env \
	{GTKDOC_DEPS_LIBS,VALGRIND_LIBS,xlib_LIBS,xlib_xrender_LIBS,xcb_LIBS,xlib_xcb_LIBS,xcb_shm_LIBS,qt_LIBS,drm_LIBS,gl_LIBS,glesv2_LIBS,cogl_LIBS,directfb_LIBS,egl_LIBS,FREETYPE_LIBS,FONTCONFIG_LIBS,LIBSPECTRE_LIBS,POPPLER_LIBS,LIBRSVG_LIBS,GOBJECT_LIBS,glib_LIBS,gtk_LIBS,png_LIBS,pixman_LIBS}=-L${LIBDIR} \
	png_LIBS="-L${LIBDIR} -lpng15" \
	png_CFLAGS=-I${INCLUDEDIR} \
	pixman_CFLAGS=-I${INCLUDEDIR} \
	pixman_LIBS="-L${LIBDIR} -lpixman-1" \
	PKG_CONFIG_PATH=${LIBDIR}/pkgconfig \
	PATH=${PREFIX}/bin:$$PATH CXX=${CXX} \
	CC="${CC} ${CFLAGS} -I${INCLUDEDIR}/pixman-1" \
	CFLAGS="${CFLAGS} -DCAIRO_NO_MUTEX=1" \
	CXXFLAGS="-DCAIRO_NO_MUTEX=1 ${CXXFLAGS}" \
	LDFLAGS="-framework Foundation -framework CoreGraphics -lpng -lpixman-1 -lfreetype -lfontconfig ${LDFLAGS}" ./configure --host=arm-apple-darwin --prefix=${PREFIX} --enable-static --disable-shared --enable-quartz --disable-quartz-font --without-x --disable-xlib --disable-xlib-xrender --disable-xcb --disable-xlib-xcb --disable-xcb-shm --enable-ft --disable-full-testing && make clean install

# CairoMM
${LIBDIR}/libcairomm-1.0.a: ${CURDIR}/cairomm ${LIBDIR}/libsigc-2.0.a
	cd cairomm && env \
	CAIROMM_CFLAGS="-I${INCLUDEDIR} -I${INCLUDEDIR}/freetype2 -I${INCLUDEDIR}/cairo -I${INCLUDEDIR}/sigc++-2.0 -I${LIBDIR}/sigc++-2.0/include" \
	CAIROMM_LIBS="-L${LIBDIR} -lcairo -lsigc-2.0 -lfontconfig" \
	CXX=${CXX} \
	CC=${CC} \
	CFLAGS="${CFLAGS}" \
	CXXFLAGS="-${CXXFLAGS}" \
	LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --prefix=${PREFIX} --disable-shared && make clean install

${CURDIR}/cairomm:
	curl http://cairographics.org/releases/cairomm-1.10.0.tar.gz > cairomm.tar.gz
	tar -xzf cairomm.tar.gz
	rm cairomm.tar.gz
	mv cairomm-1.10.0 cairomm
	patch -Np0 < cairomm.patch

# Libsigc++
${LIBDIR}/libsigc-2.0.a: ${CURDIR}/libsigc++
	cd libsigc++ && env LIBTOOL=${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/libtool \
	CXX=${CXX} \
	CC=${CC} \
	CFLAGS="${CFLAGS}" \
	CXXFLAGS="${CXXFLAGS}" \
	LDFLAGS="-Wl,-arch -Wl,${ARCH} -arch_only ${ARCH} ${LDFLAGS}" \
	./configure --host=arm-apple-darwin --prefix=${PREFIX} --disable-shared --enable-static && make clean install

${CURDIR}/libsigc++:
	curl http://ftp.gnome.org/pub/GNOME/sources/libsigc++/2.3/libsigc++-2.3.1.tar.xz > libsigc++.tar.xz
	tar -xJf libsigc++.tar.xz
	rm libsigc++.tar.xz
	mv libsigc++-2.3.1 libsigc++
	touch libsigc++

${LIBDIR}/libfontconfig.a: ${CURDIR}/fontconfig
	cd fontconfig && env LIBTOOL=${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/libtool \
	LIBXML2_CFLAGS="-I$(SYSROOT)/usr/include/libxml2" \
	LIBXML2_LIBS="-lxml2 -lz -lpthread -licucore -lm" \
	CXX=${CXX} \
	CC=${CC} \
	CFLAGS="${CFLAGS}" \
	CXXFLAGS="${CXXFLAGS}" \
	LDFLAGS="-Wl,-arch -Wl,${ARCH} -arch_only ${ARCH} ${LDFLAGS}" \
	./configure --host=arm-apple-darwin --enable-libxml2 --prefix=${PREFIX} --with-freetype-config=$PREFIX/bin/freetype-config --disable-shared --enable-static && make clean install

${CURDIR}/fontconfig:
	curl http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.10.2.tar.bz2 > fontconfig.tar.bz2
	tar xvf fontconfig.tar.bz2
	rm fontconfig.tar.bz2
	mv fontconfig-2.10.2 fontconfig
	touch fontconfig

${LIBDIR}/libsqlite3.a: ${CURDIR}/sqlite3
	cd sqlite3 && env LIBTOOL=${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/libtool \
	CXX=${CXX} \
	CC=${CC} \
	CFLAGS="${CFLAGS} -DSQLITE_THREADSAFE=1 -DSQLITE_ENABLE_RTREE=1 -DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS=1" \
	CXXFLAGS="${CXXFLAGS} -DSQLITE_THREADSAFE=1 -DSQLITE_ENABLE_RTREE=1 -DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS=1" \
	LDFLAGS="-Wl,-arch -Wl,${ARCH} -arch_only ${ARCH} ${LDFLAGS}" \
	./configure --host=arm-apple-darwin --prefix=${PREFIX} --disable-dynamic-extension --enable-static && make clean install

${CURDIR}/sqlite3:
	curl http://www.sqlite.org/sqlite-autoconf-3071502.tar.gz > sqlite3.tar.gz
	tar xzvf sqlite3.tar.gz
	rm sqlite3.tar.gz
	mv sqlite-autoconf-3071502 sqlite3
	touch sqlite3

clean:
	rm -rf libmapnik.a build cairo cairomm libsigc++ boost freetype libicu libicu_host libjpeg libpng libproj libtiff mapnik pixman fontconfig sqlite3
