PROJECTDIR=$(shell pwd)

# iOS Build variables.
OSX_SDK_ROOT=$(shell xcrun --sdk macosx --show-sdk-path)

# Version of packages that will be compiled by this meta-package
FFI_VERSION=3.2.1
PYTHON_VERSION=2.7.1
RUBICON_VERSION=0.1.2

# IPHONE build commands and flags
IPHONE_ARMV7_SDK_ROOT=$(shell xcrun --sdk iphoneos --show-sdk-path)
IPHONE_ARMV7_CC=$(shell xcrun -find -sdk iphoneos clang)
IPHONE_ARMV7_LD=$(shell xcrun -find -sdk iphoneos ld)
IPHONE_ARMV7_CFLAGS=-arch armv7 -pipe -fPIC -no-cpp-precomp -isysroot $(IPHONE_ARMV7_SDK_ROOT) -miphoneos-version-min=6.0
IPHONE_ARMV7_LDFLAGS=-arch armv7 -isysroot $(IPHONE_ARMV7_SDK_ROOT) -miphoneos-version-min=6.0

# IPHONE build commands and flags
IPHONE_ARM64_SDK_ROOT=$(shell xcrun --sdk iphoneos --show-sdk-path)
IPHONE_ARM64_CC=$(shell xcrun -find -sdk iphoneos clang)
IPHONE_ARM64_LD=$(shell xcrun -find -sdk iphoneos ld)
IPHONE_ARM64_CFLAGS=-arch arm64 -pipe -fPIC -no-cpp-precomp -isysroot $(IPHONE_ARM64_SDK_ROOT) -miphoneos-version-min=7.0
IPHONE_ARM64_LDFLAGS=-arch arm64 -isysroot $(IPHONE_ARM64_SDK_ROOT) -miphoneos-version-min=7.0

# IPHONE_SIMULATOR build commands and flags
IPHONE_SIMULATOR_SDK_ROOT=$(shell xcrun --sdk iphonesimulator --show-sdk-path)
IPHONE_SIMULATOR_CC=$(shell xcrun -find -sdk iphonesimulator clang)
IPHONE_SIMULATOR_LD=$(shell xcrun -find -sdk iphonesimulator ld)
IPHONE_SIMULATOR_CFLAGS=-arch i386 -pipe -fPIC -no-cpp-precomp -isysroot $(IPHONE_SIMULATOR_SDK_ROOT) -mios-simulator-version-min=6.0
IPHONE_SIMULATOR_LDFLAGS=-arch i386 -isysroot $(IPHONE_SIMULATOR_SDK_ROOT) -mios-simulator-version-min=6.0

# IPHONE_SIMULATOR build commands and flags
IPHONE_SIMULATOR64__SDK_ROOT=$(shell xcrun --sdk iphonesimulator --show-sdk-path)
IPHONE_SIMULATOR64_CC=$(shell xcrun -find -sdk iphonesimulator clang)
IPHONE_SIMULATOR64_LD=$(shell xcrun -find -sdk iphonesimulator ld)
IPHONE_SIMULATOR64_CFLAGS=-arch x86_64 -pipe -fPIC -no-cpp-precomp -isysroot $(IPHONE_SIMULATOR_SDK_ROOT) -mios-simulator-version-min=7.0
IPHONE_SIMULATOR64_LDFLAGS=-arch x86_64 -isysroot $(IPHONE_SIMULATOR_SDK_ROOT) -mios-simulator-version-min==7.0


all: working-dirs build/ffi.framework build/Python.framework

# Clean all builds
clean:
	rm -rf src build

# Full clean - includes all downloaded products
distclean: clean
	rm -rf downloads

###########################################################################
# Working directories
###########################################################################

download:
	mkdir -p downloads

src:
	mkdir -p src

build:
	mkdir -p build

working-dirs: download src build

###########################################################################
# libFFI
###########################################################################

# Clean the libffi project
clean-ffi:
	rm -rf src/libffi-$(FFI_VERSION)
	rm -rf build/ffi.framework

# Down original libffi source code archive.
downloads/libffi-$(FFI_VERSION).tar.gz:
	curl -L ftp://sourceware.org/pub/libffi/libffi-$(FFI_VERSION).tar.gz > downloads/libffi-$(FFI_VERSION).tar.gz

# Unpack libffi source archive into src working directory
src/libffi-$(FFI_VERSION): downloads/libffi-$(FFI_VERSION).tar.gz
	tar xvf downloads/libffi-$(FFI_VERSION).tar.gz
	mv libffi-$(FFI_VERSION) src

# Patch and build the framework
build/ffi.framework: src/libffi-$(FFI_VERSION)
#	cd src/libffi-$(FFI_VERSION) && patch -p1 -N < ../../patch/libffi/ffi-sysv.S.patch
	cd src/libffi-$(FFI_VERSION) && patch -p1 -N < ../../patch/libffi/project.pbxproj.patch
#	cd src/libffi-$(FFI_VERSION) && patch -p1 -N < ../../patch/libffi/build-ios.sh.patch
	cd src/libffi-$(FFI_VERSION) && patch -p1 -N < ../../patch/libffi/generate-darwin-source-and-headers.py.patch
	cd src/libffi-$(FFI_VERSION) && python generate-darwin-source-and-headers.py
	cd src/libffi-$(FFI_VERSION) && xcodebuild -project libffi.xcodeproj -target "Framework" -configuration Release -sdk iphoneos$(SDKVER) OTHER_CFLAGS=""
	cp -a src/libffi-$(FFI_VERSION)/build/Release-universal/ffi.framework build

###########################################################################
# rubicon-objc
###########################################################################

# Clean the libffi project
clean-rubicon-objc:
	rm -rf src/rubicon-objc-$(RUBICON_VERSION)

# Down original librubicon-objc source code archive.
downloads/rubicon-objc-$(RUBICON_VERSION).tar.gz:
	curl -L https://github.com/pybee/rubicon-objc/archive/v$(RUBICON_VERSION).tar.gz > downloads/rubicon-objc-$(RUBICON_VERSION).tar.gz

# Unpack rubicon-objc source archive into src working directory
src/rubicon-objc-$(RUBICON_VERSION): downloads/rubicon-objc-$(RUBICON_VERSION).tar.gz
	tar xvf downloads/rubicon-objc-$(RUBICON_VERSION).tar.gz
	mv rubicon-objc-$(RUBICON_VERSION) src

###########################################################################
# Python
###########################################################################

# Clean the Python project
clean-Python:
	rm -rf src/Python-$(PYTHON_VERSION)
	rm -rf build/Python.framework
	rm -rf build/python

# Down original Python source code archive.
downloads/Python-$(PYTHON_VERSION).tgz:
	curl -L https://www.python.org/ftp/python/$(PYTHON_VERSION)/Python-$(PYTHON_VERSION).tgz > downloads/Python-$(PYTHON_VERSION).tgz

# Unpack Python source archive into src working directory
src/Python-$(PYTHON_VERSION): downloads/Python-$(PYTHON_VERSION).tgz
	tar xvf downloads/Python-$(PYTHON_VERSION).tgz
	mv Python-$(PYTHON_VERSION) src

# Patch Python source with iOS patches
# Produce a dummy "patches-applied" file to mark that this has happened.
src/Python-$(PYTHON_VERSION)/build: src/Python-$(PYTHON_VERSION)
	# Apply patches
	cp patch/Python/ModulesSetup src/Python-$(PYTHON_VERSION)/Modules/Setup.local
	cp patch/Python/_scproxy.py src/Python-$(PYTHON_VERSION)/Lib/_scproxy.py
	cd src/Python-$(PYTHON_VERSION) && patch -p1 -N < ../../patch/Python/dynload.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 -N < ../../patch/Python/ssize-t-max.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 -N < ../../patch/Python/static-_sqlite3.patch
	# Configure and make the local build, providing compiled resources.
	cd src/Python-$(PYTHON_VERSION) && ./configure CC="clang -Qunused-arguments -fcolor-diagnostics" LDFLAGS="-lsqlite3" CFLAGS="--sysroot=$(OSX_SDK_ROOT)" --prefix=$(PROJECTDIR)/src/Python-$(PYTHON_VERSION)/build
	cd src/Python-$(PYTHON_VERSION) && make -j4 python.exe Parser/pgen
	cd src/Python-$(PYTHON_VERSION) && mv python.exe hostpython
	cd src/Python-$(PYTHON_VERSION) && mv Parser/pgen Parser/hostpgen
	# # Clean out all the build data
	cd src/Python-$(PYTHON_VERSION) && make distclean

build/python/ios-simulator/Python: src/Python-$(PYTHON_VERSION)/build
	# Apply extra patches for iOS simulator build
	cp patch/Python/ModulesSetup src/Python-$(PYTHON_VERSION)/Modules/Setup.local
	cat patch/Python/ModulesSetup.mobile >> src/Python-$(PYTHON_VERSION)/Modules/Setup.local
	cp patch/Python/_scproxy.py src/Python-$(PYTHON_VERSION)/Lib/_scproxy.py
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/xcompile.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/setuppath.patch
	# Configure and build Simulator library
	cd src/Python-$(PYTHON_VERSION) && ./configure CC="$(IPHONE_SIMULATOR_CC)" LD="$(IPHONE_SIMULATOR_LD)" CFLAGS="$(IPHONE_SIMULATOR_CFLAGS) -I../../build/ffi.framework/Headers" LDFLAGS="$(IPHONE_SIMULATOR_LDFLAGS) -L../../build/ffi.framework/ -lsqlite3 -undefined dynamic_lookup" --without-pymalloc --disable-toolbox-glue --prefix=/python --without-doc-strings
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/ctypes_duplicate.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/pyconfig.patch
	mkdir -p build/python/ios-simulator
	cd src/Python-$(PYTHON_VERSION) && make altbininstall libinstall inclinstall libainstall HOSTPYTHON=./hostpython CROSS_COMPILE_TARGET=yes prefix="../../build/python/ios-simulator"
	# Relocate and rename the libpython binary
	cd build/python/ios-simulator/lib && mv libpython$(basename $(PYTHON_VERSION)).a ../Python
	# Clean out all the build data
	cd src/Python-$(PYTHON_VERSION) && make distclean
	# Reverse the source patches.
	cd src/Python-$(PYTHON_VERSION) && patch -p1 -R < ../../patch/Python/xcompile.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 -R < ../../patch/Python/setuppath.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 -R < ../../patch/Python/ctypes_duplicate.patch
	# Clean up build directory
	cd build/python/ios-simulator/lib/python$(basename $(PYTHON_VERSION)) && rm config/libpython$(basename $(PYTHON_VERSION)).a config/python.o config/config.c.in config/makesetup
	cd build/python/ios-simulator/lib/python$(basename $(PYTHON_VERSION)) && rm -rf *test* lib* wsgiref bsddb curses idlelib hotshot
	cd build/python/ios-simulator/lib/python$(basename $(PYTHON_VERSION)) && find . -iname '*.pyc' | xargs rm
	cd build/python/ios-simulator/lib/python$(basename $(PYTHON_VERSION)) && find . -iname '*.py' | xargs rm
	cd build/python/ios-simulator/lib && rm -rf pkgconfig
	# Pack libraries into .zip file
	cd build/python/ios-simulator/lib/python$(basename $(PYTHON_VERSION)) && mv config ..
	cd build/python/ios-simulator/lib/python$(basename $(PYTHON_VERSION)) && mv site-packages ..
	cd build/python/ios-simulator/lib/python$(basename $(PYTHON_VERSION)) && zip -r ../python27.zip *
	cd build/python/ios-simulator/lib/python$(basename $(PYTHON_VERSION)) && rm -rf *
	cd build/python/ios-simulator/lib/python$(basename $(PYTHON_VERSION)) && mv ../config .
	cd build/python/ios-simulator/lib/python$(basename $(PYTHON_VERSION)) && mv ../site-packages .
	# Move all headers except for pyconfig.h into a Headers directory
	mkdir -p build/python/ios-simulator/Headers
	cd build/python/ios-simulator/Headers && mv ../include/python$(basename $(PYTHON_VERSION))/* .
	cd build/python/ios-simulator/Headers && mv pyconfig.h ../include/python$(basename $(PYTHON_VERSION))

build/python/ios-simulator64/Python: src/Python-$(PYTHON_VERSION)/build
	# Apply extra patches for iOS simulator build
	cp patch/Python/ModulesSetup src/Python-$(PYTHON_VERSION)/Modules/Setup.local
	cat patch/Python/ModulesSetup.mobile >> src/Python-$(PYTHON_VERSION)/Modules/Setup.local
	cp patch/Python/_scproxy.py src/Python-$(PYTHON_VERSION)/Lib/_scproxy.py
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/xcompile.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/setuppath.patch
	# Configure and build Simulator library
	cd src/Python-$(PYTHON_VERSION) && ./configure CC="$(IPHONE_SIMULATOR_CC)" LD="$(IPHONE_SIMULATOR64_LD)" CFLAGS="$(IPHONE_SIMULATOR64_CFLAGS) -I../../build/ffi.framework/Headers" LDFLAGS="$(IPHONE_SIMULATOR64_LDFLAGS) -L../../build/ffi.framework/ -lsqlite3 -undefined dynamic_lookup" --without-pymalloc --disable-toolbox-glue --prefix=/python --without-doc-strings
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/ctypes_duplicate.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/pyconfig-arm64.patch
	mkdir -p build/python/ios-simulator64
	cd src/Python-$(PYTHON_VERSION) && make altbininstall libinstall inclinstall libainstall HOSTPYTHON=./hostpython CROSS_COMPILE_TARGET=yes prefix="../../build/python/ios-simulator64"
	# Relocate and rename the libpython binary
	cd build/python/ios-simulator64/lib && mv libpython$(basename $(PYTHON_VERSION)).a ../Python
	# Clean out all the build data
	cd src/Python-$(PYTHON_VERSION) && make distclean
	# Reverse the source patches.
	cd src/Python-$(PYTHON_VERSION) && patch -p1 -R < ../../patch/Python/xcompile.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 -R < ../../patch/Python/setuppath.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 -R < ../../patch/Python/ctypes_duplicate.patch
	# Clean up build directory
	cd build/python/ios-simulator64/lib/python$(basename $(PYTHON_VERSION)) && rm config/libpython$(basename $(PYTHON_VERSION)).a config/python.o config/config.c.in config/makesetup
	cd build/python/ios-simulator64/lib/python$(basename $(PYTHON_VERSION)) && rm -rf *test* lib* wsgiref bsddb curses idlelib hotshot
	cd build/python/ios-simulator64/lib/python$(basename $(PYTHON_VERSION)) && find . -iname '*.pyc' | xargs rm
	cd build/python/ios-simulator64/lib/python$(basename $(PYTHON_VERSION)) && find . -iname '*.py' | xargs rm
	cd build/python/ios-simulator64/lib && rm -rf pkgconfig
	# Pack libraries into .zip file
	cd build/python/ios-simulator64/lib/python$(basename $(PYTHON_VERSION)) && mv config ..
	cd build/python/ios-simulator64/lib/python$(basename $(PYTHON_VERSION)) && mv site-packages ..
	cd build/python/ios-simulator64/lib/python$(basename $(PYTHON_VERSION)) && zip -r ../python27.zip *
	cd build/python/ios-simulator64/lib/python$(basename $(PYTHON_VERSION)) && rm -rf *
	cd build/python/ios-simulator64/lib/python$(basename $(PYTHON_VERSION)) && mv ../config .
	cd build/python/ios-simulator64/lib/python$(basename $(PYTHON_VERSION)) && mv ../site-packages .
	# Move all headers except for pyconfig.h into a Headers directory
	mkdir -p build/python/ios-simulator64/Headers
	cd build/python/ios-simulator64/Headers && mv ../include/python$(basename $(PYTHON_VERSION))/* .
	cd build/python/ios-simulator64/Headers && mv pyconfig.h ../include/python$(basename $(PYTHON_VERSION))


build/python/ios-armv7/Python: src/Python-$(PYTHON_VERSION)/build
	# Apply extra patches for iPhone build
	cp patch/Python/ModulesSetup src/Python-$(PYTHON_VERSION)/Modules/Setup.local
	cat patch/Python/ModulesSetup.mobile >> src/Python-$(PYTHON_VERSION)/Modules/Setup.local
	cp patch/Python/_scproxy.py src/Python-$(PYTHON_VERSION)/Lib/_scproxy.py
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/xcompile.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/setuppath.patch
	# Configure and build iPhone library
	cd src/Python-$(PYTHON_VERSION) && ./configure CC="$(IPHONE_ARMV7_CC)" LD="$(IPHONE_ARMV7_LD)" CFLAGS="$(IPHONE_ARMV7_CFLAGS) -I../../build/ffi.framework/Headers" LDFLAGS="$(IPHONE_ARMV7_LDFLAGS) -L../../build/ffi.framework/ -lsqlite3 -undefined dynamic_lookup" --without-pymalloc --disable-toolbox-glue --host=armv7-apple-darwin --prefix=/python --without-doc-strings
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/ctypes_duplicate.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/pyconfig.patch
	mkdir -p build/python/ios-armv7
	cd src/Python-$(PYTHON_VERSION) && make altbininstall libinstall inclinstall libainstall HOSTPYTHON=./hostpython CROSS_COMPILE_TARGET=yes prefix="../../build/python/ios-armv7"
	# Relocate and rename the libpython binary
	cd build/python/ios-armv7/lib && mv libpython$(basename $(PYTHON_VERSION)).a ../Python
	# Clean out all the build data
	cd src/Python-$(PYTHON_VERSION) && make distclean
	# Reverse the source patches.
	cd src/Python-$(PYTHON_VERSION) && patch -p1 -R < ../../patch/Python/xcompile.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 -R < ../../patch/Python/setuppath.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 -R < ../../patch/Python/ctypes_duplicate.patch
	# Clean up build directory
	cd build/python/ios-armv7/lib/python$(basename $(PYTHON_VERSION)) && rm config/libpython$(basename $(PYTHON_VERSION)).a config/python.o config/config.c.in config/makesetup
	cd build/python/ios-armv7/lib/python$(basename $(PYTHON_VERSION)) && rm -rf *test* lib* wsgiref bsddb curses idlelib hotshot
	cd build/python/ios-armv7/lib/python$(basename $(PYTHON_VERSION)) && find . -iname '*.pyc' | xargs rm
	cd build/python/ios-armv7/lib/python$(basename $(PYTHON_VERSION)) && find . -iname '*.py' | xargs rm
	cd build/python/ios-armv7/lib && rm -rf pkgconfig
	# Pack libraries into .zip file
	cd build/python/ios-armv7/lib/python$(basename $(PYTHON_VERSION)) && mv config ..
	cd build/python/ios-armv7/lib/python$(basename $(PYTHON_VERSION)) && mv site-packages ..
	cd build/python/ios-armv7/lib/python$(basename $(PYTHON_VERSION)) && zip -r ../python27.zip *
	cd build/python/ios-armv7/lib/python$(basename $(PYTHON_VERSION)) && rm -rf *
	cd build/python/ios-armv7/lib/python$(basename $(PYTHON_VERSION)) && mv ../config .
	cd build/python/ios-armv7/lib/python$(basename $(PYTHON_VERSION)) && mv ../site-packages .
	# Move all headers except for pyconfig.h into a Headers directory
	mkdir -p build/python/ios-armv7/Headers
	cd build/python/ios-armv7/Headers && mv ../include/python$(basename $(PYTHON_VERSION))/* .
	cd build/python/ios-armv7/Headers && mv pyconfig.h ../include/python$(basename $(PYTHON_VERSION))

build/python/ios-arm64/Python: src/Python-$(PYTHON_VERSION)/build
	# Apply extra patches for iPhone build
	cp patch/Python/ModulesSetup src/Python-$(PYTHON_VERSION)/Modules/Setup.local
	cat patch/Python/ModulesSetup.mobile >> src/Python-$(PYTHON_VERSION)/Modules/Setup.local
	cp patch/Python/_scproxy.py src/Python-$(PYTHON_VERSION)/Lib/_scproxy.py
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/xcompile.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/setuppath.patch
	# Configure and build iPhone library
	cd src/Python-$(PYTHON_VERSION) && ./configure CC="$(IPHONE_ARM64_CC)" LD="$(IPHONE_ARM64_LD)" CFLAGS="$(IPHONE_ARM64_CFLAGS) -I../../build/ffi.framework/Headers" LDFLAGS="$(IPHONE_ARM64_LDFLAGS) -L../../build/ffi.framework/ -lsqlite3 -undefined dynamic_lookup" --without-pymalloc --disable-toolbox-glue --host=arm64-apple-darwin --prefix=/python --without-doc-strings
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/ctypes_duplicate.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 < ../../patch/Python/pyconfig-arm64.patch
	mkdir -p build/python/ios-arm64
	cd src/Python-$(PYTHON_VERSION) && make altbininstall libinstall inclinstall libainstall HOSTPYTHON=./hostpython CROSS_COMPILE_TARGET=yes prefix="../../build/python/ios-arm64"
	# Relocate and rename the libpython binary
	cd build/python/ios-arm64/lib && mv libpython$(basename $(PYTHON_VERSION)).a ../Python
	# Clean out all the build data
	cd src/Python-$(PYTHON_VERSION) && make distclean
	# Reverse the source patches.
	cd src/Python-$(PYTHON_VERSION) && patch -p1 -R < ../../patch/Python/xcompile.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 -R < ../../patch/Python/setuppath.patch
	cd src/Python-$(PYTHON_VERSION) && patch -p1 -R < ../../patch/Python/ctypes_duplicate.patch
	# Clean up build directory
	cd build/python/ios-arm64/lib/python$(basename $(PYTHON_VERSION)) && rm config/libpython$(basename $(PYTHON_VERSION)).a config/python.o config/config.c.in config/makesetup
	cd build/python/ios-arm64/lib/python$(basename $(PYTHON_VERSION)) && rm -rf *test* lib* wsgiref bsddb curses idlelib hotshot
	cd build/python/ios-arm64/lib/python$(basename $(PYTHON_VERSION)) && find . -iname '*.pyc' | xargs rm
	cd build/python/ios-arm64/lib/python$(basename $(PYTHON_VERSION)) && find . -iname '*.py' | xargs rm
	cd build/python/ios-arm64/lib && rm -rf pkgconfig
	# Pack libraries into .zip file
	cd build/python/ios-arm64/lib/python$(basename $(PYTHON_VERSION)) && mv config ..
	cd build/python/ios-arm64/lib/python$(basename $(PYTHON_VERSION)) && mv site-packages ..
	cd build/python/ios-arm64/lib/python$(basename $(PYTHON_VERSION)) && zip -r ../python27.zip *
	cd build/python/ios-arm64/lib/python$(basename $(PYTHON_VERSION)) && rm -rf *
	cd build/python/ios-arm64/lib/python$(basename $(PYTHON_VERSION)) && mv ../config .
	cd build/python/ios-arm64/lib/python$(basename $(PYTHON_VERSION)) && mv ../site-packages .
	# Move all headers except for pyconfig.h into a Headers directory
	mkdir -p build/python/ios-arm64/Headers
	cd build/python/ios-arm64/Headers && mv ../include/python$(basename $(PYTHON_VERSION))/* .
	cd build/python/ios-arm64/Headers && mv pyconfig.h ../include/python$(basename $(PYTHON_VERSION))

build/Python.framework: build/python/ios-simulator/Python build/python/ios-simulator64/Python build/python/ios-armv7/Python build/python/ios-arm64/Python src/rubicon-objc-$(RUBICON_VERSION)
	# Create the framework directory from the compiled resrouces
	mkdir -p build/Python.framework/Versions/$(basename $(PYTHON_VERSION))/
	cd build/Python.framework/Versions && ln -fs $(basename $(PYTHON_VERSION)) Current
	# Copy the headers from the simulator build
	cp -r build/python/ios-simulator64/Headers build/Python.framework/Versions/$(basename $(PYTHON_VERSION))/Headers
	cd build/Python.framework && ln -fs Versions/Current/Headers
	# Copy the standard library from the simulator build
	mkdir -p build/Python.framework/Versions/$(basename $(PYTHON_VERSION))/Resources
	cp -r build/python/ios-simulator/lib build/Python.framework/Versions/$(basename $(PYTHON_VERSION))/Resources
	cp -r build/python/ios-simulator64/lib build/Python.framework/Versions/$(basename $(PYTHON_VERSION))/Resources
	cd build/Python.framework && ln -fs Versions/Current/Resources
	# Copy the pyconfig headers from the builds, and install the fat header.
	mkdir -p build/Python.framework/Versions/$(basename $(PYTHON_VERSION))/Resources/include/python$(basename $(PYTHON_VERSION))
	cp build/python/ios-simulator/include/python$(basename $(PYTHON_VERSION))/pyconfig.h build/Python.framework/Versions/$(basename $(PYTHON_VERSION))/Resources/include/python$(basename $(PYTHON_VERSION))/pyconfig-simulator.h
	cp build/python/ios-simulator64/include/python$(basename $(PYTHON_VERSION))/pyconfig.h build/Python.framework/Versions/$(basename $(PYTHON_VERSION))/Resources/include/python$(basename $(PYTHON_VERSION))/pyconfig-simulator64.h
	cp build/python/ios-armv7/include/python$(basename $(PYTHON_VERSION))/pyconfig.h build/Python.framework/Versions/$(basename $(PYTHON_VERSION))/Resources/include/python$(basename $(PYTHON_VERSION))/pyconfig-armv7.h
	cp build/python/ios-arm64/include/python$(basename $(PYTHON_VERSION))/pyconfig.h build/Python.framework/Versions/$(basename $(PYTHON_VERSION))/Resources/include/python$(basename $(PYTHON_VERSION))/pyconfig-arm64.h
	cp patch/Python/pyconfig.h build/Python.framework/Versions/$(basename $(PYTHON_VERSION))/Resources/include/python$(basename $(PYTHON_VERSION))/
	# Build a fat library with all targets included.
	xcrun lipo -create -output build/Python.framework/Versions/Current/Python build/python/ios-simulator/Python build/python/ios-simulator64/Python build/python/ios-armv7/Python build/python/ios-arm64/Python
	cd build/Python.framework && ln -fs Versions/Current/Python
	# Install Rubicon into site packages.
	cd src && cp -r rubicon-objc-$(RUBICON_VERSION)/rubicon ../build/Python.framework/Resources/lib/python$(basename $(PYTHON_VERSION))/site-packages/
	# Clean up temporary build dirs
	rm -rf build/python

env:
	# PYTHON_VERSION $(PYTHON_VERSION)
	# FFI_VERSION $(FFI_VERSION)
	# OSX_SDK_ROOT $(OSX_SDK_ROOT)

	# IPHONE_ARMV7_SDK_ROOT $(IPHONE_ARMV7_SDK_ROOT)
	# IPHONE_ARMV7_CC $(IPHONE_ARMV7_CC)
	# IPHONE_ARMV7_LD $(IPHONE_ARMV7_LD)
	# IPHONE_ARMV7_CFLAGS $(IPHONE_ARMV7_CFLAGS)
	# IPHONE_ARMV7_LDFLAGS $(IPHONE_ARMV7_LDFLAGS)

	# IPHONE_ARM64_SDK_ROOT $(IPHONE_ARM64_SDK_ROOT)
	# IPHONE_ARM64_CC $(IPHONE_ARM64_CC)
	# IPHONE_ARM64_LD $(IPHONE_ARM64_LD)
	# IPHONE_ARM64_CFLAGS $(IPHONE_ARM64_CFLAGS)
	# IPHONE_ARM64_LDFLAGS $(IPHONE_ARM64_LDFLAGS)

	# IPHONE_SIMULATOR_SDK_ROOT $(IPHONE_SIMULATOR_SDK_ROOT)
	# IPHONE_SIMULATOR_CC $(IPHONE_SIMULATOR_CC)
	# IPHONE_SIMULATOR_LD $(IPHONE_SIMULATOR_LD)
	# IPHONE_SIMULATOR_CFLAGS $(IPHONE_SIMULATOR_CFLAGS)
	# IPHONE_SIMULATOR_LDFLAGS $(IPHONE_SIMULATOR_LDFLAGS)

	# IPHONE_SIMULATOR64_SDK_ROOT $(IPHONE_SIMULATOR_SDK_ROOT)
	# IPHONE_SIMULATOR64_CC $(IPHONE_SIMULATOR_CC)
	# IPHONE_SIMULATOR64_LD $(IPHONE_SIMULATOR_LD)
	# IPHONE_SIMULATOR64_CFLAGS $(IPHONE_SIMULATOR_CFLAGS)
	# IPHONE_SIMULATOR64_LDFLAGS $(IPHONE_SIMULATOR_LDFLAGS)
