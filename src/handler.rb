module Handler
  require 'strscan'
  Dir["callbacks/*.rb"].each {|file| require file }
  
  def initialize *args
    raise "config.yml is not valid or does not exists" unless args[0] and args[0][:config]
    @config = args[0][:config]
  end

  def receive_data data
    trigger_callbacks data
  end
  
  protected
  
  def trigger_callbacks string
    @config["patterns"].each do |key,value|
      regex = Regexp.compile(@config["patterns"][key]["regex"],@config["patterns"][key]["regex_case_insensitive"])
      string.scan(regex).each do |match|
        eval(@config["patterns"][key]["callback"])
      end
    end
  end
  
  def test_callback match
    puts "pattern matched: #{match}"
  end
  
end