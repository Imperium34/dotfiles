#!/bin/bash

grep -v '^\s*#' ~/.config/quickshell/scripts/quotes.txt | grep -v '^\s*$' | shuf -n 1 | fold -s -w 50
