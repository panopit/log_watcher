#!/usr/bin/env ruby 

# == Synopsis 
#   Log Watcher is a simple log watcher with event machine.
#
# == Examples
#   This command runs log watcher daemon in the background
#     watcher
#
#   This command reads the configuration from an alternate file:
#     watcher -c config_file
#
#   Here we run in the foreground
#     watcher -f
#
# == Usage 
#   watcher [options]
#
#   For help use: watcher -h
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
require 'rubygems'
require 'yaml'
require 'ostruct'
require "bundler"
Bundler.setup
Bundler.require
require 'eventmachine'
require 'eventmachine-tail'
require './src/mailee'

class Watcher

  VERSION = '0.0.1'

  attr_reader :options
 
  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    
    # Set default options
    @options = OpenStruct.new
    @options.config_file = 'config.yml'
    @options.log_file = 'watcher.log'
    @options.pid_file = 'watcher.pid'
    @options.foreground = false
    
    @config = nil
    @pid_file = nil
  end
  
  def run
      check_pid
      parse_options            
      read_config
      
      # if -f is not present we fork into the background and write maileed.pid
      @options.foreground ? process_command : daemonize
  end
  
  protected
  
  def check_pid
    pid = File.read(@options.pid_file).to_i
    begin
      Process.kill(0,pid)
    rescue
      return
    end
    raise "Mailee Log Watcher is already running"
  end
  
  def remove_pid
    if !@pid_file.nil? and File.exist? @pid_file
      puts "Removing pid file #{@pid_file}..." 
      File.unlink @pid_file
    end
  end

  def read_config    
    begin
      @config = YAML.load_file( @options.config_file )       
    rescue => e      
      puts "Error reading config file #{@options.config_file}: #{e.inspect}"
      exit
    end
  end
  
  
  def daemonize
    begin
      @pid_file = @options.pid_file 
      pid = fork do
        process_command
      end
      File.open(@pid_file, 'w+'){|f| f.write pid.to_s }
      Process.detach(pid)
    rescue Exception => e
      puts "Error while daemonizing: #{e.inspect}"
      exit
    end
  end
  
  def parse_options
    opts = OptionParser.new 
    opts.on('-v', '--version')            { puts "watcher version #{VERSION}" ; exit 0 }
    opts.on('-h', '--help')               { puts opts; exit 0  }
    #opts.on('-V', '--verbose')            { @options.verbose = true }  
    opts.on('-f', '--foreground')         { @options.foreground = true }
    #opts.on('-l', '--log log_file')       { |log_file| @options.log_file = log_file }
    opts.on('-p', '--pid pid_file')       { |pid_file| @options.pid_file = pid_file }
    #opts.on('-c', '--conf config_file')   { |conf| @options.config_file = conf }

    opts.parse!(@arguments)
  end


  def process_command
    $0 = 'mailee - log watcher'
    raise 'Invalid Config, missing paths directives' unless @config["paths"]
    @conn = PGconn.open(@config['database'])

    last_access = @conn.exec("SELECT EXTRACT (epoch FROM created_at) FROM accesses WHERE type='#{Mailee::Access.query_type}' ORDER BY created_at desc LIMIT 1")[0]["date_part"]
    last_click = @conn.exec("SELECT EXTRACT (epoch FROM created_at) FROM accesses WHERE type='#{Mailee::Click.query_type}' ORDER BY created_at desc LIMIT 1")[0]["date_part"]

    p1 = fork {Mailee::Sync.new(@config["paths"]["access_log"], @config, last_access, Mailee::Access).run}
    p2 = fork {Mailee::Sync.new(@config["paths"]["click_log"], @config, last_click, Mailee::Click).run}
    
    EventMachine.run do
        EventMachine::file_tail(@config["paths"]["access_log"], Mailee::Access)  
        EventMachine::file_tail(@config["paths"]["click_log"], Mailee::Click)  
    end
  end
  
    
end

app = Watcher.new(ARGV, STDIN)
app.run
