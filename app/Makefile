serve:
	((sleep 5; curl http://teamzones.dev:8080/_tools/provision) &)
	goapp serve -clear_datastore .

test:
	goapp test teamzones/{app,integrations,forms,models,utils}

deploy: test
	appcfg.py update --no_cookies .
