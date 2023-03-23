#!/usr/bin/env bash

nvm install v16

cd ${CODESPACE_VSCODE_FOLDER}/frontend-react-js && npm i
cd ${CODESPACE_VSCODE_FOLDER}/cognito-authz && npm i
cd ${CODESPACE_VSCODE_FOLDER}/backend-flask && pip install -r requirements.tx