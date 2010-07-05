#!/usr/bin/env ruby 

# == Synopsis 
#   Log Watcher is a simple log watcher with event machine.
#
# == Examples
#   This command runs the mailer daemon in the background
#     maileed
#
#   This command reads the configuration from an alternate file:
#     maileed -c config_file
#
#   Here we run in the foreground
#     maileed -f
#
# == Usage 
#   maileed [options] -c config_file
#
#   For help use: maileed -h
#
# == Options
#   -h, --help          Displays help message
#   -v, --version       Display the version, then exit
#   -f, --foreground    Run the maileed in the foreground (usefull for reading the verbose output)
#   -V, --verbose       Verbose output
#   -l, --log           Defines the path to log file
#   -p, --pid           Defines the directory for maileed.pid
#   -c, --conf          Defines the path to the config file
#   -m, --memory        Start with the memory profiler
#
# == Author
#   Pedro Axelrud (http://github.com/pedroaxl), Softa (http://softa.com.br).
#
# == Copyright
#   Copyright (c) 2009 Softa. Licensed under the MIT License:
#   http://www.opensource.org/licenses/mit-license.php


require 'optparse'
require "bundler"
Bundler.setup
require 'rubygems'
require 'yaml'
require 'eventmachine'

require 'src/handler'

config_file = YAML.load_file('config.yml')


EM.run {
  config_file.each do |key,value|
    EM.popen("tail -f #{config_file[key]["path"]}", Handler, {:config=> config_file[key]})
  end
}