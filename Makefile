PROJECT = AnimeVsubIOS.xcodeproj
SCHEME = AnimeVsubIOS
CONFIGURATION = Release
SDK = iphoneos
OUTPUT_DIR = build
IPA_NAME = AnimeVsubIOS.ipa

.PHONY: all build ipa clean open

all: ipa

build:
	@echo "🔨 Building $(SCHEME) for iOS 12+ ($(SDK))..."
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-sdk $(SDK) \
		-derivedDataPath $(OUTPUT_DIR)/DerivedData \
		CODE_SIGNING_ALLOWED=NO \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGN_IDENTITY=""

ipa: build
	@echo "📦 Packaging unsigned IPA..."
	@mkdir -p $(OUTPUT_DIR)/Payload
	@APP_PATH=$$(find $(OUTPUT_DIR)/DerivedData -name "AnimeVsubIOS.app" -path "*/Release-iphoneos/*" | head -1); \
	if [ -z "$$APP_PATH" ]; then \
		echo "❌ App bundle not found"; exit 1; \
	fi; \
	cp AnimeVsubIOS/Resources/iTunesMetadata.plist "$$APP_PATH/"; \
	codesign -s - --force --deep "$$APP_PATH"; \
	cp -r "$$APP_PATH" $(OUTPUT_DIR)/Payload/; \
	cp AnimeVsubIOS/Resources/iTunesMetadata.plist $(OUTPUT_DIR)/; \
	cd $(OUTPUT_DIR) && zip -r -9 $(IPA_NAME) Payload iTunesMetadata.plist && rm -rf Payload iTunesMetadata.plist; \
	echo "✅ IPA created: $(OUTPUT_DIR)/$(IPA_NAME)"

clean:
	@rm -rf $(OUTPUT_DIR)
	@rm -rf ~/Library/Developer/Xcode/DerivedData/AnimeVsubIOS-*

open:
	open $(PROJECT)
