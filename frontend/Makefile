STATIC_DIR = ../app/static
EMAIL_DIR = ../app/templates/_emails
TARGET_CSS = $(STATIC_DIR)/css/app.css
TARGET_LIB = $(STATIC_DIR)/js/lib.js
TARGET_APP = $(STATIC_DIR)/js/app.js
TARGET_INVITE_EMAIL = $(EMAIL_DIR)/invite.html.tmpl
TARGET_RECOVER_EMAIL = $(EMAIL_DIR)/recover-password.html.tmpl
OBJS = $(TARGET_CSS) $(TARGET_LIB) $(TARGET_APP) $(TARGET_INVITE_EMAIL) $(TARGET_RECOVER_EMAIL)
ELM_SOURCES = $(shell find src -name "*.elm" -print)

.PHONY: all min

all: $(OBJS)

$(TARGET_CSS): css/*.scss
	node-sass css/app.scss $(TARGET_CSS)
	node-sass css/checkout.scss $(STATIC_DIR)/css/checkout.css

$(TARGET_LIB): lib/*.js
	browserify lib/index.js -o $(TARGET_LIB)

$(TARGET_APP): $(ELM_SOURCES)
	elm make --warn src/Main.elm --output=$(TARGET_APP)

$(TARGET_INVITE_EMAIL): email/invite.mjml
	mjml -s email/invite.mjml > $(TARGET_INVITE_EMAIL)

$(TARGET_RECOVER_EMAIL): email/recover-password.mjml
	mjml -s email/recover-password.mjml > $(TARGET_RECOVER_EMAIL)

min: all
	uglifycss ../app/static/css/app.css  >../app/static/css/app.min.css
	uglifycss ../app/static/css/checkout.css > ../app/static/css/checkout.min.css
	mv ../app/static/css/app.min.css ../app/static/css/app.css
	mv ../app/static/css/checkout.min.css ../app/static/css/checkout.css
	uglifyjs --compress --mangle -- ../app/static/js/app.js > ../app/static/js/app.min.js
	uglifyjs --compress --mangle -- ../app/static/js/lib.js > ../app/static/js/lib.min.js
	mv ../app/static/js/app.min.js ../app/static/js/app.js
	mv ../app/static/js/lib.min.js ../app/static/js/lib.js
