USER_DOCS_MD := $(wildcard doc/*.md)
USER_DOCS_HTML := $(patsubst doc/%.md,assets/%.html,$(USER_DOCS_MD))

# Developer documentation files built from *.md to assets/dev/*.html
DEV_DOCS_MD := $(wildcard plan.md README.md GEMINI.md)
DEV_DOCS_HTML := $(patsubst %.md,assets/dev/%.html,$(DEV_DOCS_MD))

FIREBASE_FILES := lib/firebase_options.dart android/app/google-services.json firebase.json

ASSETS := web/favicon.ico web/favicon.png web/privacy.html web/privacy_es.html web/terms.html web/terms_es.html $(USER_DOCS_HTML) $(FIREBASE_FILES) assets/mesh/cell600.json assets/mesh/cell120.json

.PHONY: docs build_all stage release ASSETS audit stage-release test

docs: $(USER_DOCS_HTML) $(DEV_DOCS_HTML) web/privacy.html web/privacy_es.html web/terms.html web/terms_es.html

assets/%.html: doc/%.md
	@mkdir -p assets
	pandoc $< -s --mathml --css=css/doc_style.css -o $@

assets/dev/%.html: %.md
	@mkdir -p assets/dev
	pandoc $< -f markdown-yaml_metadata_block -s --mathml --metadata pagetitle="$*" --css=../css/doc_style.css -o $@

web/%.html: assets/%.html
	@mkdir -p web/css
	cp -f assets/css/doc_style.css web/css/doc_style.css 2>/dev/null || true
	cp -f $< $@

build_all: $(ASSETS)
	flutter build web
	echo XXX flutter build apk

web/favicon.png: assets/icons/icon.png
	convert $< -background transparent -colorspace RGB -filter Lanczos -resize 32x32 -colorspace sRGB $@

web/favicon.ico: assets/icons/icon.png
	convert $< -define icon:auto-resize=64,48,32,16 -background transparent $@
	dart run flutter_launcher_icons

assets/icons/icon.png assets/icons/foreground.png assets/icons/background.png: icon.xcf
	icon-generate icon.xcf

ASSETS: $(ASSETS)

assets/mesh/cell600.json assets/mesh/cell120.json: tool/generate_polychora.dart
	dart run tool/generate_polychora.dart

test: $(ASSETS)
	flutter test --exclude-tags release_audit

audit: $(ASSETS)
	flutter test test/audit_test.dart

stage:  $(ASSETS)
	flutter build web
	echo "PURPLE: Beginning push to staging."
	firebase_stage.pl

stage-release: $(ASSETS) audit
	flutter build web
	echo "PURPLE: Beginning push to staging."
	firebase_stage.pl

release: $(ASSETS) audit
	make build_all
	firebase_release.pl


# If this fails, you might have to run "firebase login" or maybe
# "firebase logout" followed by  "firebase login".
$(FIREBASE_FILES):
	flutterfire configure -y
