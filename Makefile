PAGE_FILES = $(shell find . -maxdepth 1 -type f -name '*.html')
CSS_FILES = $(shell find . -maxdepth 1 -type f -name '*.css')
IMG_FILES = $(shell find img/ -type f)
FONT_FILES = $(shell find fonts/ -type f)

BUILD_STATIC_DIR=build

PAGE_TARGETS = $(patsubst %,$(BUILD_STATIC_DIR)/%,$(PAGE_FILES))
CSS_TARGETS = $(patsubst %,$(BUILD_STATIC_DIR)/%,$(CSS_FILES))
IMG_TARGETS = $(patsubst %,$(BUILD_STATIC_DIR)/%,$(IMG_FILES))
FONT_TARGETS = $(patsubst %,$(BUILD_STATIC_DIR)/%,$(FONT_FILES))

MINIFY?=yes

all: $(PAGE_TARGETS) $(CSS_TARGETS) $(JS_TARGETS) $(IMG_TARGETS) $(FONT_TARGETS)

COL_BLACK   =\\x1b[30m
COL_RED     =\\x1b[31m
COL_GREEN   =\\x1b[32m
COL_YELLOW  =\\x1b[33m
COL_BLUE    =\\x1b[34m
COL_MAGENTA =\\x1b[35m
COL_CYAN    =\\x1b[36m
COL_WHITE   =\\x1b[37;1m
COL_GREY    =\\x1b[37m
COL_RST     =\\x1b[0m

TXT_COMPRESSING=$(COL_GREEN)"Compressing"$(COL_RST)
TXT_COPYING     =$(COL_BLUE)"Copying    "$(COL_RST)
TXT_BUILDING    =$(COL_CYAN)"Building   "$(COL_RST)
TXT_CLEANING  =$(COL_YELLOW)"Cleaning   "$(COL_RST)

$(PAGE_TARGETS): $(BUILD_STATIC_DIR)/%.html: %.html
	@if [[ "$(MINIFY)" == "yes" ]]; then \
		echo -e "$(TXT_COMPRESSING) $< $(COL_GREY)=>$(COL_RST) $@"; \
		(echo "changecom(<!--,-->)dnl"; cat $<) \
		| m4 \
		| htmlcompressor --remove-intertag-spaces --remove-quotes --simple-doctype \
			--remove-style-attr --remove-link-attr --remove-script-attr --remove-form-attr \
			--remove-input-attr --simple-bool-attr --remove-js-protocol --remove-http-protocol \
			--remove-https-protocol --remove-surrounding-spaces --compress-js --compress-css \
			--js-compressor closure \
		| sed 's/\/\/www.google.com/https:\/\/www.google.com/' \
		> $@; \
	else \
		echo -e "$(TXT_COPYING) $< $(COL_GREY)=>$(COL_RST) $@"; \
		(echo "changecom(<!--,-->)dnl"; cat $<) \
		| m4 \
		> $@; \
	fi

$(CSS_TARGETS): $(BUILD_STATIC_DIR)/%.css: %.css
	@if [[ "$(MINIFY)" == "yes" ]]; then \
		echo -e "$(TXT_COMPRESSING) $< $(COL_GREY)=>$(COL_RST) $@"; \
		yuicompressor $< -o $@; \
	else \
		echo -e "$(TXT_COPYING) $< $(COL_GREY)=>$(COL_RST) $@"; \
		cp $< $@; \
	fi


$(IMG_TARGETS): $(BUILD_STATIC_DIR)/img/%: img/%
	@mkdir -p build/img
	@if [[ "$(MINIFY)" == "yes" ]] && [[ $< == *.png ]]; then \
		echo -e "$(TXT_COMPRESSING) $< $(COL_GREY)=>$(COL_RST) $@"; \
		optipng -clobber --out=$@ $<; \
	elif [[ "$(MINIFY)" == "yes" ]] && [[ $< == *.jpg ]]; then \
		echo -e "$(TXT_COMPRESSING) $< $(COL_GREY)=>$(COL_RST) $@"; \
		cp $< $@; \
		jpegoptim --strip-all $@; \
	else \
		echo -e "$(TXT_COPYING) $< $(COL_GREY)=>$(COL_RST) $@"; \
		cp $< $@; \
	fi
	@mv build/img/favicon.ico build/

$(FONT_TARGETS): $(BUILD_STATIC_DIR)/%: %
	@mkdir -p build/fonts
	@echo -e "$(TXT_COPYING) $< $(COL_GREY)=>$(COL_RST) $@"; \
	cp $< $@

clean:
	@echo -e "$(TXT_CLEANING)..."
	@rm -rf $(BUILD_STATIC_DIR)/*

push:
	@echo -e "$(COL_CYAN)Pushing to server..."
	rsync --partial --progress --recursive ./build/* 124.250.210.14:/var/www/html/

.PHONY:
	clean
	push
