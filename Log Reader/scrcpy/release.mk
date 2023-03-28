# This makefile provides recipes to build a "portable" version of scrcpy for
# Windows.
#
# Here, "portable" means that the client and server binaries are expected to be
# anywhere, but in the same directory, instead of well-defined separate
# locations (e.g. /usr/bin/scrcpy and /usr/share/scrcpy/scrcpy-server).
#
# In particular, this implies to change the location from where the client push
# the server to the device.

.PHONY: default clean \
	test \
	build-server \
	prepare-deps \
	build-win32 build-win64 \
	dist-win32 dist-win64 \
	zip-win32 zip-win64 \
	release

GRADLE ?= ./gradlew

TEST_BUILD_DIR := build-test
SERVER_BUILD_DIR := build-server
WIN32_BUILD_DIR := build-win32
WIN64_BUILD_DIR := build-win64

VERSION := $(shell git describe --tags --always)

DIST := dist
WIN32_TARGET_DIR := scrcpy-win32-$(VERSION)
WIN64_TARGET_DIR := scrcpy-win64-$(VERSION)
WIN32_TARGET := $(WIN32_TARGET_DIR).zip
WIN64_TARGET := $(WIN64_TARGET_DIR).zip

RELEASE_DIR := release-$(VERSION)

release: clean test build-server zip-win32 zip-win64
	mkdir -p "$(RELEASE_DIR)"
	cp "$(SERVER_BUILD_DIR)/server/scrcpy-server" \
		"$(RELEASE_DIR)/scrcpy-server-$(VERSION)"
	cp "$(DIST)/$(WIN32_TARGET)" "$(RELEASE_DIR)"
	cp "$(DIST)/$(WIN64_TARGET)" "$(RELEASE_DIR)"
	cd "$(RELEASE_DIR)" && \
		sha256sum "scrcpy-server-$(VERSION)" \
			"scrcpy-win32-$(VERSION).zip" \
			"scrcpy-win64-$(VERSION).zip" > SHA256SUMS.txt
	@echo "Release generated in $(RELEASE_DIR)/"

clean:
	$(GRADLE) clean
	rm -rf "$(DIST)" "$(TEST_BUILD_DIR)" "$(SERVER_BUILD_DIR)" \
		"$(WIN32_BUILD_DIR)" "$(WIN64_BUILD_DIR)"

test:
	[ -d "$(TEST_BUILD_DIR)" ] || ( mkdir "$(TEST_BUILD_DIR)" && \
		meson setup "$(TEST_BUILD_DIR)" -Db_sanitize=address )
	ninja -C "$(TEST_BUILD_DIR)"
	$(GRADLE) -p server check

build-server:
	[ -d "$(SERVER_BUILD_DIR)" ] || ( mkdir "$(SERVER_BUILD_DIR)" && \
		meson setup "$(SERVER_BUILD_DIR)" --buildtype release -Dcompile_app=false )
	ninja -C "$(SERVER_BUILD_DIR)"

prepare-deps:
	@app/prebuilt-deps/prepare-adb.sh
	@app/prebuilt-deps/prepare-sdl.sh
	@app/prebuilt-deps/prepare-ffmpeg.sh
	@app/prebuilt-deps/prepare-libusb.sh

build-win32: prepare-deps
	[ -d "$(WIN32_BUILD_DIR)" ] || ( mkdir "$(WIN32_BUILD_DIR)" && \
		meson setup "$(WIN32_BUILD_DIR)" \
			--cross-file cross_win32.txt \
			--buildtype release --strip -Db_lto=true \
			-Dcompile_server=false \
			-Dportable=true )
	ninja -C "$(WIN32_BUILD_DIR)"

build-win64: prepare-deps
	[ -d "$(WIN64_BUILD_DIR)" ] || ( mkdir "$(WIN64_BUILD_DIR)" && \
		meson setup "$(WIN64_BUILD_DIR)" \
			--cross-file cross_win64.txt \
			--buildtype release --strip -Db_lto=true \
			-Dcompile_server=false \
			-Dportable=true )
	ninja -C "$(WIN64_BUILD_DIR)"

dist-win32: build-server build-win32
	mkdir -p "$(DIST)/$(WIN32_TARGET_DIR)"
	cp "$(SERVER_BUILD_DIR)"/server/scrcpy-server "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp "$(WIN32_BUILD_DIR)"/app/scrcpy.exe "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/data/scrcpy-console.bat "$(DIST)/$(WIN32_TARGET_DIR)"
	cp app/data/scrcpy-noconsole.vbs "$(DIST)/$(WIN32_TARGET_DIR)"
	cp app/data/icon.png "$(DIST)/$(WIN32_TARGET_DIR)"
	cp app/data/open_a_terminal_here.bat "$(DIST)/$(WIN32_TARGET_DIR)"
	cp app/prebuilt-deps/data/ffmpeg-6.0-scrcpy-2/win32/bin/avutil-58.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-6.0-scrcpy-2/win32/bin/avcodec-60.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-6.0-scrcpy-2/win32/bin/avformat-60.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-6.0-scrcpy-2/win32/bin/swresample-4.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-6.0-scrcpy-2/win32/bin/zlib1.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/platform-tools-34.0.1/adb.exe "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/platform-tools-34.0.1/AdbWinApi.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/platform-tools-34.0.1/AdbWinUsbApi.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/SDL2-2.26.4/i686-w64-mingw32/bin/SDL2.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/libusb-1.0.26/libusb-MinGW-Win32/bin/msys-usb-1.0.dll "$(DIST)/$(WIN32_TARGET_DIR)/"

dist-win64: build-server build-win64
	mkdir -p "$(DIST)/$(WIN64_TARGET_DIR)"
	cp "$(SERVER_BUILD_DIR)"/server/scrcpy-server "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp "$(WIN64_BUILD_DIR)"/app/scrcpy.exe "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/data/scrcpy-console.bat "$(DIST)/$(WIN64_TARGET_DIR)"
	cp app/data/scrcpy-noconsole.vbs "$(DIST)/$(WIN64_TARGET_DIR)"
	cp app/data/icon.png "$(DIST)/$(WIN64_TARGET_DIR)"
	cp app/data/open_a_terminal_here.bat "$(DIST)/$(WIN64_TARGET_DIR)"
	cp app/prebuilt-deps/data/ffmpeg-6.0-scrcpy-2/win64/bin/avutil-58.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-6.0-scrcpy-2/win64/bin/avcodec-60.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-6.0-scrcpy-2/win64/bin/avformat-60.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-6.0-scrcpy-2/win64/bin/swresample-4.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-6.0-scrcpy-2/win64/bin/zlib1.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/platform-tools-34.0.1/adb.exe "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/platform-tools-34.0.1/AdbWinApi.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/platform-tools-34.0.1/AdbWinUsbApi.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/SDL2-2.26.4/x86_64-w64-mingw32/bin/SDL2.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/libusb-1.0.26/libusb-MinGW-x64/bin/msys-usb-1.0.dll "$(DIST)/$(WIN64_TARGET_DIR)/"

zip-win32: dist-win32
	cd "$(DIST)"; \
		zip -r "$(WIN32_TARGET)" "$(WIN32_TARGET_DIR)"

zip-win64: dist-win64
	cd "$(DIST)"; \
		zip -r "$(WIN64_TARGET)" "$(WIN64_TARGET_DIR)"
