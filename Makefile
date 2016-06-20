EMAIL_DIR       = app/templates/_emails
EMAIL_ROOT      = frontend/email
EMAIL_INVITE_T  = $(EMAIL_DIR)/invite.html.tmpl
EMAIL_RECOVER_T = $(EMAIL_DIR)/recover-password.html.tmpl
EMAIL_TARGETS   = $(EMAIL_INVITE_T) $(EMAIL_RECOVER_T)

JS_DIR 		= app/static/js
JS_ROOT     = frontend/lib
JS_SOURCES  = $(shell find  $(JS_ROOT) -name "*.js"   -print)
JS_TARGET   = $(JS_DIR)/lib.js
JS_TARGET_M = $(JS_TARGET).min

CSS_DIR	 	= app/static/css
CSS_ROOT    = frontend/css
CSS_SOURCES = $(shell find $(CSS_ROOT) -name "*.scss" -print)
CSS_PRES_T  = $(CSS_DIR)/presentation.css
CSS_APP_T   = $(CSS_DIR)/app.css
CSS_CHECK_T = $(CSS_DIR)/checkout.css
CSS_TARGETS = $(CSS_PRES_T) $(CSS_APP_T) $(CSS_CHECK_T)

ELM_ROOT     = frontend/src
ELM_SOURCES  = $(shell find $(ELM_ROOT) -name "*.elm"  -print)
ELM_TARGET   = $(JS_DIR)/app.js
ELM_TARGET_M = $(ELM_TARGET).min

TEST_SOURCES = teamzones/{app,integrations,forms,models,utils}

OBJS = $(EMAIL_TARGETS) $(CSS_TARGETS) $(JS_TARGET) $(ELM_TARGET)

.PHONY: all credentials deploy deploy_ install min serve test

all: $(OBJS)

credentials:
	test -f app/credentials/braintree_production.yaml

deploy: credentials min test
	appcfg.py update --no_cookies app

deploy_: credentials min
	appcfg.py update --no_cookies app

install:
	goapp install -v teamzones/...
	go install -v teamzones/...

min: $(OBJS)
	uglifyjs $(JS_TARGET) -o $(JS_TARGET_M) -c
	uglifyjs $(ELM_TARGET) -o $(ELM_TARGET_M) -c
	mv $(JS_TARGET_M) $(JS_TARGET)
	mv $(ELM_TARGET_M) $(ELM_TARGET)

serve: $(OBJS) install
	((sleep 3; curl http://teamzones.dev:8080/_tools/provision) &)
	goapp serve -clear_datastore app

test: install
	goapp test $(TEST_SOURCES)

$(CSS_PRES_T): $(CSS_SOURCES)
	node-sass $(CSS_ROOT)/presentation.scss $(CSS_PRES_T)

$(CSS_APP_T): $(CSS_SOURCES)
	node-sass $(CSS_ROOT)/app.scss $(CSS_APP_T)

$(CSS_CHECK_T): $(CSS_SOURCES)
	node-sass $(CSS_ROOT)/checkout.scss $(CSS_CHECK_T)

$(JS_TARGET): $(JS_SOURCES)
	cd frontend && browserify ../$(JS_ROOT)/index.js -o ../$(JS_TARGET)

$(ELM_TARGET): $(ELM_SOURCES)
	cd frontend && elm make --warn src/Main.elm --output=../$(ELM_TARGET)

$(EMAIL_INVITE_T): $(EMAIL_ROOT)/invite.mjml
	mjml -s $(EMAIL_ROOT)/invite.mjml > $(EMAIL_INVITE_T)

$(EMAIL_RECOVER_T): $(EMAIL_ROOT)/recover-password.mjml
	mjml -s $(EMAIL_ROOT)/recover-password.mjml > $(EMAIL_RECOVER_T)
