all: js elm

js: lib/*.js
	browserify lib/index.js -o ../app/static/js/lib.js

elm: src/*.elm
	elm make src/Main.elm --output=../app/static/js/app.js

watch:
	fswatch -o lib src | xargs -n1 -I{} make all
