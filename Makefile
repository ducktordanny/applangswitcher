APP := build/AppLangswitcher.app

.PHONY: app run install icon clean

app:
	swift build -c release
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp .build/release/AppLangswitcher $(APP)/Contents/MacOS/
	cp Support/Info.plist $(APP)/Contents/
	cp Support/AppIcon.icns $(APP)/Contents/Resources/
	codesign --force --sign - $(APP)

run: app
	pkill -x AppLangswitcher || true
	open $(APP)

install: app
	pkill -x AppLangswitcher || true
	rm -rf /Applications/AppLangswitcher.app
	cp -R $(APP) /Applications/
	open /Applications/AppLangswitcher.app

icon:
	swift scripts/make-icon.swift Support/AppIcon.icns docs/icon.png

clean:
	rm -rf .build build
