#!/bin/bash

svstat /service/sphinx | awk -F '\)| ' '{print $4}' > /findmjob.com/log/searchd.pid;
/usr/local/bin/indexer --all --config /findmjob.com/etc/sphinx.conf --rotate;