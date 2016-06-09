TEST_SOURCES = teamzones/{app,integrations,forms,models,utils}

.PHONY: serve test deploy

serve:
	goapp install -v && go install -v
	((sleep 3; curl http://teamzones.dev:8080/_tools/provision) &)
	goapp serve -clear_datastore .

test:
	goapp test $(TEST_SOURCES)

deploy: test
	appcfg.py update --no_cookies .
