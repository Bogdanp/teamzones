all: style javascript elm

style: css/*.scss
	node-sass css/app.scss ../app/static/css/app.css
	node-sass css/checkout.scss ../app/static/css/checkout.css

javascript: lib/*.js
	browserify lib/index.js -o ../app/static/js/lib.js

elm: src/*.elm
	elm make --warn src/Main.elm --output=../app/static/js/app.js

watch:
	fswatch -r css lib src | xargs -n1 ./bin/watch

min: all
	uglifycss css/normalize.css > ../app/static/css/normalize.css
	uglifycss ../app/static/css/app.css  >../app/static/css/app.min.css
	uglifycss ../app/static/css/checkout.css > ../app/static/css/checkout.min.css
	mv ../app/static/css/app.min.css ../app/static/css/app.css
	mv ../app/static/css/checkout.min.css ../app/static/css/checkout.css
	uglifyjs --compress --mangle -- ../app/static/js/app.js > ../app/static/js/app.min.js
	uglifyjs --compress --mangle -- ../app/static/js/lib.js > ../app/static/js/lib.min.js
	mv ../app/static/js/app.min.js ../app/static/js/app.js
	mv ../app/static/js/lib.min.js ../app/static/js/lib.js
