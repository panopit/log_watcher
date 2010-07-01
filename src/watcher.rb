require 'rubygems'
require 'yaml'
require 'eventmachine'
require 'handler'

config_file = YAML.load_file('config.yml')


EM.run {
  config_file.each do |key|
    EM.watch_file(config_file[key]["path"], Handler)
  end
}