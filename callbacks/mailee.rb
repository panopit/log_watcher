class MaileeCallbacks
  require 'redis'
  require 'redis/namespace'
  
  ROOT_DOMAINS = ["com","net","br","me","ar","us","info","org","mobi","biz","co","ca"]
  SLEEP_TIME = 300
  THRESHOLD_EXPIRE = 3600 # seconds
  @regex_instance = Regexp.new("^.*#{`hostname`.chomp} ([\\w\\-\\_]*)\\/.*$", true)
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
    sleep || SLEEP_TIME    
  end
  
  def self.hold mx, time
    r = (Marshal.load @redis.get(mx)) rescue {}
    hash = {:greylisted_until => Time.now + time}
    if r[:messages_sent] and (r[:messages_sent].last + THRESHOLD_EXPIRE) >= hash[:greylisted_until]
      expire = r[:messages_sent].last + THRESHOLD_EXPIRE - Time.now 
    else
      expire = time 
    end
    @redis.setex(mx, expire.to_i, Marshal.dump(hash.merge(r)))
   end  
  
end