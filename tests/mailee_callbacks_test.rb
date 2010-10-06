class MaileeCallbacksTest < Test::Unit::TestCase
  
  DEFAULT_SLEEP_TIME = 300
    
  def setup
    @m1 = "Jun 14 06:10:49 #{`hostname`.chomp} postfix/smtp[19812]: 6B31141CBE: to=<afin@webcenter.com.br>, relay=ostrich.birdsnet.com.br[189.91.32.6]:25, delay=1.1, delays=0.09/0/0.87/0.15, dsn=4.0.0, status=deferred (host ostrich.birdsnet.com.br[189.91.32.6] said: 450 Rcpt to <> - You are greylisted. Try again later (in reply to RCPT TO command))"
    @m2 = "Jun 14 09:23:20 #{`hostname`.chomp} l0/smtp[30991]: 3509E41CC0: host mx2.mdbrasil.com.br[201.71.240.9] said: 454 Falha tempor?ria, pol?tica SoftFail (greylisting). (#5.7.1) (in reply to RCPT TO command)"
    @m3 = "Jun 14 17:15:56 #{`hostname`.chomp} postfix-m10/smtp[26952]: B4FD943932: host a.mx.mail.yahoo.com[67.195.168.31] refused to talk to me: 421 4.7.0 [TS01]"
    @m4 = "Jun 14 09:23:35 #{`hostname`.chomp} postfix/smtp[31161]: E95EF41CF0: to=<calnil@netsite.com.br>, relay=servmail.netsite.com.br[200.233.202.7]:25, delay=0.75, delays=0.09/0/0.48/0.19, dsn=4.7.1, status=deferred (host servmail.netsite.com.br[200.233.202.7] said: 450 4.7.1 <calnil@netsite.com.br>: Recipient address rejected: Greylisted for 2 minutes (in reply to RCPT TO command))"
    @m5 = "Jun 14 09:23:38 #{`hostname`.chomp} postfix/smtp[31449]: 4E2E941CD2: to=<asesturb@stz.flash.tv.br>, relay=mercurio.sertaozinho.flash.tv.br[189.39.152.8]:25, delay=0.94, delays=0.09/0/0.65/0.19, dsn=4.7.1, status=deferred (host mercurio.sertaozinho.flash.tv.br[189.39.152.8] said: 450 4.7.1 <asesturb@stz.flash.tv.br>: Recipient address rejected: Greylisted for 300 seconds (see http://www.flash.tv.br/grey) (in reply to RCPT TO command))"
    @mexp = "Jun 14 09:23:38 #{`hostname`.chomp} postfix/smtp[31449]: 4E2E941CD2: to=<asesturb@stz.flash.tv.br>, relay=mercurio.sertaozinho.flash.tv.br[189.39.152.8]:25, delay=0.94, delays=0.09/0/0.65/0.19, dsn=4.7.1, status=deferred (host mercurio.sertaozinho.flash.tv.br[189.39.152.8] said: 450 4.7.1 <asesturb@stz.flash.tv.br>: Recipient address rejected: Greylisted for 1 seconds (see http://www.flash.tv.br/grey) (in reply to RCPT TO command))"
    
  end
  
  def test_match_should_parse_the_data
    match = {:instance_name => 'postfix', :mx => 'ostrich.birdsnet.com.br', :sleep => DEFAULT_SLEEP_TIME}
    assert_equal match, MaileeCallbacks.parse_match(@m1)
    match = {:instance_name => 'l0', :mx => 'mx2.mdbrasil.com.br', :sleep => DEFAULT_SLEEP_TIME}
    assert_equal match, MaileeCallbacks.parse_match(@m2)
    match = {:instance_name => 'postfix-m10', :mx => 'a.mx.mail.yahoo.com', :sleep => DEFAULT_SLEEP_TIME}
    assert_equal match, MaileeCallbacks.parse_match(@m3)
    match = {:instance_name => 'postfix', :mx => 'servmail.netsite.com.br', :sleep => 120}
    assert_equal match, MaileeCallbacks.parse_match(@m4)
    match = {:instance_name => 'postfix', :mx => 'mercurio.sertaozinho.flash.tv.br', :sleep => 300}
    assert_equal match, MaileeCallbacks.parse_match(@m5)
  end
  
  def test_sleep_time_should_get_the_sleep_time
    assert_equal DEFAULT_SLEEP_TIME, MaileeCallbacks.sleep_time(@m1)
    assert_equal DEFAULT_SLEEP_TIME, MaileeCallbacks.sleep_time(@m2)
    assert_equal DEFAULT_SLEEP_TIME, MaileeCallbacks.sleep_time(@m3)
    assert_equal 120, MaileeCallbacks.sleep_time(@m4)
    assert_equal 300, MaileeCallbacks.sleep_time(@m5)
  end
  
  def test_hold_should_create_key_if_doesnt_exists   
    msg = MaileeCallbacks.parse_match @m1
    @redis = Redis::Namespace.new(msg[:instance_name], :redis => Redis.new)
    @redis.del(msg[:mx])
    MaileeCallbacks.greylist @m1, nil
    r = Marshal.load @redis.get(msg[:mx])
    t = Time.new
    assert_not_nil r[:greylisted_until]
    @redis.del(msg[:mx])
  end
    #nil
  
  def test_hold_should_expire_key_while_creating
    msg = MaileeCallbacks.parse_match @mexp
    @redis = Redis::Namespace.new(msg[:instance_name], :redis => Redis.new)
    @redis.del(msg[:mx])
    MaileeCallbacks.greylist @mexp, nil
    assert_not_nil @redis.get(msg[:mx])
    sleep 2
    assert_equal nil, @redis.get(msg[:mx])
    @redis.del(msg[:mx])
  end
    #nil
  
  def test_hold_should_merge_key_if_already_exists
    msg = MaileeCallbacks.parse_match @m1
    @redis = Redis::Namespace.new(msg[:instance_name], :redis => Redis.new)
    hash = {:a => [0,1,2], :b => 'aaa'}
    @redis.set(msg[:mx], Marshal.dump(hash))
    MaileeCallbacks.greylist @m1, nil
    hash_new = Marshal.load @redis.get(msg[:mx])
    assert_equal [0,1,2], hash_new[:a]
    assert_equal 'aaa', hash_new[:b]
    assert_not_nil hash_new[:greylisted_until]
    @redis.del(msg[:mx])
  end
  
  def test_should_have_different_namespaces
    msg3 = MaileeCallbacks.parse_match @m3
    @redis3 = Redis::Namespace.new(msg3[:instance_name], :redis => Redis.new)
    MaileeCallbacks.greylist @m3, nil
    msg4 = MaileeCallbacks.parse_match @m4
    @redis4 = Redis::Namespace.new(msg4[:instance_name], :redis => Redis.new)
    MaileeCallbacks.greylist @m4, nil
    assert_not_nil @redis3.get msg3[:mx]
    assert_not_nil @redis4.get msg4[:mx]
    assert_nil @redis3.get msg4[:mx]
    assert_nil @redis4.get msg3[:mx]
    @redis3.del msg3[:mx]
    @redis4.del msg3[:mx]
  end
  
  def test_key_should_expire_when_the_last_message_sent_expire
    hash = {:a => [0,1,2], :b => 'aaa', :messages_sent => [Time.now - 3600 + 3]}
    msg = MaileeCallbacks.parse_match @mexp
    @redis = Redis::Namespace.new(msg[:instance_name], :redis => Redis.new)
    @redis.set(msg[:mx], Marshal.dump(hash))
    MaileeCallbacks.greylist @mexp, nil
    assert_not_nil @redis.get(msg[:mx])
    sleep 2
    assert_not_nil @redis.get(msg[:mx])
    sleep 2
    assert_nil @redis.get(msg[:mx])
        
    @redis.del(msg[:mx])
  end
  
end