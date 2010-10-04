class MaileeCallbacks
  require 'redis'
  require 'redis/namespace'
  require 'yajl'
  
  ROOT_DOMAINS = ["com","net","br","me","ar","us","info","org","mobi","biz","co","ca"]
  DEFAULT_SLEEP_TIME = 300
  @regex_instance = Regexp.new("^.*#{`hostname`.chomp} ([\w\-\_]*)\/.*$", true)
  @regex_relay = Regexp.new('^.*?(?=relay=([\w\.\-\_]*?)\[).*$',true)
  @regex_host = Regexp.new('^.*(?=host\s?([a-z0-9\.\-\_]*)\[).*$',true)
  @regex_time = Regexp.new('^.*?(\d+)\s?(minute|second).*?$',true)
  
  
  
  def self.greylist match, log
    msg_data = parse_match match
    @redis = Redis::Namespace.new(msg_data[:instance_name], :redis => Redis.new)
    hold msg_data[:mx], msg_data[:sleep]
  end
  
  protected
  
  def self.parse_match match
    match =~ @regex_instance
    instance = $~[1]
    match =~ @regex_relay  
    relay = $~[1] if $~
    unless relay
      match =~ @regex_host
      relay = $~[1]
    end
    {:instance_name => instance, :mx => relay, :sleep => sleep_time(match)}
  end
  
  def self.sleep_time match
    match =~ @regex_time
    if $~
     sleep = $~[1].to_i
     sleep = sleep * 60 if $~[2] == 'minute'  
    end 
    sleep || DEFAULT_SLEEP_TIME    
  end
  
  def self.hold mx, time
    r = @redis.get mx
    hash = {:greylisted_until => Time.now + time}
    if r
      hash.merge! Yajl::Parser.parse(r)
      @redis.set(mx, Yajl::Encoder.encode(hash))
    else
      @redis.setex(mx, time, Yajl::Encoder.encode(hash))      
    end
   end  
  
#   def self.release_postfix domain, time
#         #  $7=sender, $8=recipient1, $9=recipient2
#         c = <<COMMAND 
#               sleep #{time} && mailq | grep -v '^ *(' | awk  'BEGIN { RS = "" }
#                      {   split($8,domain,"@"); 
#                          if (domain[2] == "#{domain}")
#                                print $1 }
#                      ' | tr -d '*!' | postqueue -H 
# COMMAND
#     #    IO.popen c
#     @log.info "postfix: messages to #{domain} will be released in #{time} seconds"
#   end
#   
#   # def self.release_maileed domain
#   #   redis.del(domain, true)
#   #   @log.info "maileed: messages to #{domain} are released"
#   # end  
  
  
end