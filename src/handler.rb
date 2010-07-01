module Handler
  require 'strscan'

  def receive_data data
    puts data
  end
  
  def config(path)
    config_file = YAML.load_file('config.yml')
    config_file.each{|key,value| return config_file[key] if value["path"] == path}
  end
  
  def trigger_callbacks string, config
    config["patterns"].each do |key,value|
      matches = 0
      while(string.scan("/#{key["regex"]}/"))
        matches += 1 
      end
      matches.times eval(key["callback"])
    end
  end
  
end