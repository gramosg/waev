#!/bin/sh

npm run deploy --prefix ./assets/
mix phx.digest
