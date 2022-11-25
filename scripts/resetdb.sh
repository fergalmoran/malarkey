#!/usr/bin/env bash
echo Dropping exiting db
dropdb -f --if-exists -h localhost -U postgres malarkey_dev
echo Creating new db
createdb -h localhost -U postgres malarkey_dev

mix ecto.migrate
