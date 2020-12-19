#!/bin/sh
#
# LaunchBar Action Script
#

export PATH=/usr/local/opt/ruby/bin:/Users/carlos.fonseca/.gems/2.7.0/bin:$PATH
export GEM_HOME=~/.gems/2.7.0

cd ~/Developer/Mine/CartaoDa
bundle exec run.rb
