module Handler
  require 'strscan'
  Dir["callbacks/*.rb"].each {|file| require file }
  
  def initialize *args
    raise "config.yml is not valid or does not exists" unless args[0] and args[0][:config]
    @config = args[0][:config]
    @log = args[0][:log]
  end

  def receive_data data
    trigger_callbacks data
  end
  
  protected
  
  def trigger_callbacks string
    @config["patterns"].each do |key,value|
      string.scan(@config["patterns"][key]["regex"]).each do |match|
        eval(@config["patterns"][key]["callback"])
      end
    end
  end
  
end