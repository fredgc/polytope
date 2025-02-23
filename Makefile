build_all: web/favicon.ico
	flutter build apk
	flutter build web

web/favicon.ico: assets/icon/icon.png
	convert -resize x32 $<  -flatten -colors 256  -background transparent $@
	dart run flutter_launcher_icons

test:
	flutter test

release:
	make build_all
	firebase deploy


lib/firebase_options.dart: 
	flutterfire configure -y
