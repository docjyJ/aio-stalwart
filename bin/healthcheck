#!/bin/bash

test "$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:10003/healthz/ready)" == "200"
