#!/usr/bin/env bash

gh codespace ports visibility 3000:public -c $CODESPACE_NAME
gh codespace ports visibility 4318:public -c $CODESPACE_NAME
gh codespace ports visibility 4567:public -c $CODESPACE_NAME
gh codespace ports visibility 8800:public -c $CODESPACE_NAME