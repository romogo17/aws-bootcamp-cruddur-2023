#!/usr/bin/env bash

nvm install v16

pushd frontend-react-js && npm i && popd
pushd cognito-authz && npm i && popd
pushd backend-flask && pip install -r requirements.tx && popd