serve:
	((sleep 5; curl http://teamzones.dev:8080/_tools/provision) &)
	goapp serve -clear_datastore .

deploy:
	appcfg.py update --no_cookies .
