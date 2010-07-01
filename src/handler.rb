module Handler
  require 'strscan'

  def initialize
    @position = 0
  end
  
  def file_modified 
    f = File.new(path,"r")
    f.seek(@position, IO::SEEK_CUR) # rescue @position = 0
    s = StringScanner.new f.read
    trigger_callbacks s, config(path)
    f.close
  end
  
  def file_moved
    puts "#{path} moved"    
  end
  
  def file_deleted
    puts "#{path} deleted"    
  end
  
  def unbind
    puts "#{path} monitoring ceased"    
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