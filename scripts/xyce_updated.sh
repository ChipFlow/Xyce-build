#!/bin/bash
exit $(curl -s https://api.github.com/repos/xyce/xyce/commits/master | jq -r "((now - (.commit.author.date | fromdateiso8601) )  / (60*60*24)  | trunc)")
