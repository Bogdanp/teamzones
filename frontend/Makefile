all: style javascript elm

style: css/*.scss
	node-sass css/app.scss ../app/static/css/app.css

javascript: lib/*.js
	browserify lib/index.js -o ../app/static/js/lib.js

elm: src/*.elm
	elm make --warn src/Main.elm --output=../app/static/js/app.js

watch:
	fswatch -r css lib src | xargs -n1 ./bin/watch
