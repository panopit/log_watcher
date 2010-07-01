require 'rubygems'
require 'yaml'
require 'eventmachine'
require 'src/handler'

config_file = YAML.load_file('config.yml')


EM.run {
  config_file.each do |key,value|
    EM.popen("tail -f #{config_file[key]["path"]}", Handler)
  end
}