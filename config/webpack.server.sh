#!/usr/bin/env bash

export NODE_ENV=development
export NODE_OPTIONS="--max-old-space-size=3584"
export DEV_SERVER_PORT=${DEV_SERVER_PORT:=3808}
export WEBPACK_COMPILE_ONCE=${WEBPACK_COMPILE_ONCE:=false}

# Common function for nodemon, which calls the executable from node_modules, as
# `yarn run` creates one more intermediate process noone needs.
#
# We replace this bash script's process with the nodemon one's with the help of exec
#
# We ignore nodemons update check
#
# Watching for changes on config/webpack.config.js
# If we change the webpack config, we restart the process.
#
# We define SIGTERM as the signal for killing processes created by nodemon
function nodemon {
  exec node_modules/.bin/nodemon \
    --no-update-notifier \
    --watch 'config/webpack.config.js' \
    --signal SIGTERM "$@"
}

if [ "$WEBPACK_COMPILE_ONCE" == "true" ]; then
  echo "Starting webserver on http://localhost:$DEV_SERVER_PORT"
  echo "You are starting webpack in compile-once mode"
  echo "The JavaScript assets are recompiled only if they change"
  echo "If you change them often, you might wanna unset WEBPACK_COMPILE_ONCE"
  echo "You can enforce recompiling by running \`pgrep -f nodemon | xargs kill -USR2\`"
  
  # We only compile once at the start and serve the assets with a static file server
  #
  # In order to make branch switches or updates a bit more convienent, we watch for
  # changes in the source folders in order to recompile the assets
  nodemon --watch "app/assets/javascripts" \
    --watch "ee/app/assets/javascripts" \
    --ext js,json,vue \
    --delay 1 \
    --exec "yarn run webpack &&
        exec ruby -run -e httpd public/ -p $DEV_SERVER_PORT"
else
  # Default case. Utilizing Webpack dev server.
  # It's quite memory expensive, but does hot reloading, recompiling and watching for us
  nodemon --exec "webpack-dev-server --config config/webpack.config.js"
fi