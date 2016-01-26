#!/bin/bash

service postgresql start
dspace.build
service postgresql stop

