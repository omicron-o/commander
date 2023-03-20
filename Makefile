.PHONY: all build clean release release-zip release-tar

BUILD_DIR := ./build
RELEASE_DIR := ./release
SRC_DIR := ./src
MEDIA_DIR := ./media

all: release-zip release-tar
	

release: build
	mkdir -p $(RELEASE_DIR)

build: clean
	mkdir -p $(BUILD_DIR)
	cp -r $(SRC_DIR) $(BUILD_DIR)/Commander
	mkdir -p $(BUILD_DIR)/Commander/media/textures
	#cp -r $(MEDIA_DIR)/textures/*.tga $(BUILD_DIR)/Commander/textures/
	cp -r $(MEDIA_DIR)/fonts $(BUILD_DIR)/Commander/media/fonts
	cp LICENSE.md $(BUILD_DIR)/Commander/
	#cp CHANGELOG.md $(BUILD_DIR)/Commander/

release-zip: release
	7z a -tzip $(RELEASE_DIR)/commander.zip -w $(BUILD_DIR)/.

release-tar: release
	tar -cJf $(RELEASE_DIR)/commander.tar.xz -C $(BUILD_DIR) Commander
	tar -czf $(RELEASE_DIR)/commander.tar.gz -C $(BUILD_DIR) Commander

clean:
	rm -rf $(BUILD_DIR) $(RELEASE_DIR)
