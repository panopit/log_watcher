require 'eventmachine'
require 'eventmachine-tail'
require './src/mailee.rb'

class MaileeTest < Test::Unit::TestCase

  def setup
    setup_files
    @conn = PGconn.open(@config['database'])
    create_delivery
  end

  def teardown
    delete_delivery
    remove_files
  end

  def test_should_parse_access_line
    result = ["1315863905.666","192.168.56.1","curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5","/go/view/24234234"]
    assert_equal result, Mailee::Access.parse_line("1315863905.666|192.168.56.1|GET /go/view/24234234 HTTP/1.1|curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5")
  end

  def test_should_parse_id
    assert_equal 24234234, Mailee::Stats.parse_id('/go/view/24234234')
    assert_equal 24234234, Mailee::Stats.parse_id('/go/click/24234234?key=3123&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123')
  end

  def test_should_parse_url
    assert_equal 'http://mailee.me?name=john&code=123', Mailee::Stats.parse_url('/go/click/24234234?key=3123&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123')
  end

  def test_should_insert_access
    result = ["1315863905.666","192.168.56.1","curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5","/go/view/999"]    
    @m = Mailee::Access.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT * FROM accesses WHERE message_id = 999")[0]
    assert_equal '2011-09-12 18:45:05.666', r["created_at"]
    assert_equal '999', r["message_id"]
    assert_equal 'View', r["type"]
    assert_equal '192.168.56.1', r["ip"]
    assert_equal 'curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5', r["user_agent_string"]
    assert_equal '888', r["contact_id"]
  end

  def test_should_not_insert_duplicate_values
    result = ["1315863905.666","192.168.56.1","curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5","/go/view/999"]    
    @m = Mailee::Access.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]["count"]
    assert_equal 1, r.to_i
    @m.insert_into_db(result)
    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]["count"]
    assert_equal 2, r.to_i

    @m.insert_into_db(result,true)
    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]["count"]
    assert_equal 2, r.to_i

  end

  def test_should_not_insert_access_from_test
    @conn.exec("UPDATE deliveries SET test = true WHERE id = 999")
    result = ["1315863905.666","192.168.56.1","curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5","/go/view/999"]    
    @m = Mailee::Access.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")
    assert_equal 0, r[0]["count"].to_i
  end

  def test_should_parse_click_line
    result = ["1315941774.461","192.168.56.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1","/go/click/24234234?key=3123&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123"]
    assert_equal result, Mailee::Click.parse_line("1315941774.461|192.168.56.1|GET /go/click/24234234?key=3123&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123 HTTP/1.1|Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1")
  end

  def test_should_insert_click_line
    result = ["1315941774.461","192.168.56.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1","/go/click/999?key=3123&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123"]    
    @m = Mailee::Click.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT * FROM accesses WHERE message_id = 999")[0]
    assert_equal '2011-09-13 16:22:54.461', r["created_at"]
    assert_equal '999', r["message_id"]
    assert_equal 'Click', r["type"]
    assert_equal '192.168.56.1', r["ip"]
    assert_equal 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1', r["user_agent_string"]
    assert_equal '888', r["contact_id"]
    assert_equal '777', r["url_id"]
  end

  def test_should_not_insert_twice_the_same_click_line
    result = ["1315941774.461","192.168.56.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1","/go/click/999?key=3123&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123"]    
    @m = Mailee::Click.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]["count"]    
    assert_equal 1, r.to_i
    @m.insert_into_db(result)
    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]["count"]    
    assert_equal 2, r.to_i
    @m.insert_into_db(result,true)
    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]["count"]    
    assert_equal 2, r.to_i
  
  end
  
  def test_should_not_insert_click_from_test
    @conn.exec("UPDATE deliveries SET test = true WHERE id = 999")    
    result = ["1315941774.461","192.168.56.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1","/go/click/999?key=3123&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123"]    
    @m = Mailee::Click.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]
    assert_equal 0,r["count"].to_i
  end

  def test_should_sync_files
    @conn.exec("INSERT into deliveries (id, message_id, contact_id, smtp_relay_id, email) VALUES (998,999,888,999,'aaa@gmail.com');")
    @conn.exec("INSERT into deliveries (id, message_id, contact_id, smtp_relay_id, email) VALUES (997,999,888,999,'aaa@gmail.com');")
    result = ["1315941774.461","192.168.56.1","GET /go/view/999 HTTP/1.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1"]    
    result2 = ["1315941773.461","192.168.56.1","GET /go/view/998 HTTP/1.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1"]    
    result3 = ["1315941772.461","192.168.56.1","GET /go/view/997 HTTP/1.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1"]    
    File.open("sync.log",'w') {|f| f.write([result3.join('|'), result2.join('|'), result.join('|')].join("\n"))}
    
    Mailee::Access.new('sync.log').insert_into_db(Mailee::Access.parse_line(result.join('|')))

    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]["count"].to_i
    assert_equal r, 1

    m = Mailee::Sync.new('sync.log', @config, Mailee::Access)
    m.run

    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]["count"].to_i
    assert_equal r, 3 
    FileUtils.rm('sync.log')
  end

  def setup_files
    yaml = '---
    database:
      host: localhost
      port: 5432
      dbname: mailee_test
      user: log_watcher
      password: 1234
      '
    FileUtils.mv('config.yml','original.config.yml')
    File.open('config.yml', 'w'){|f| f.write yaml  }
    FileUtils.touch("test.log")
    @config = YAML.load(yaml)
    @config['database']['user'] = 'mailee'
  end

  def remove_files
    FileUtils.rm('config.yml')
    FileUtils.rm('test.log')
    FileUtils.mv('original.config.yml','config.yml')  
  end

  def create_delivery
   @conn.exec("INSERT into clients (id,name,subdomain) VALUES ('999','acme','acme')")
    @conn.exec("INSERT into messages (id, client_id, title, subject, from_name, from_email, reply_email) VALUES ('999','999','A','A','A','aaa@softa.com.br','aaa@softa.com.br');")
    @conn.exec("INSERT into contact_status (id,name) VALUES (0,'a');") rescue nil
    @conn.exec("INSERT into contacts (id, client_id, email) VALUES (888,999, 'aaaaa@softa.com.br');")
    @conn.exec("INSERT into lists (id, client_id, name) VALUES (999,999,'a');")
    @conn.exec("INSERT into lists_contacts (id, list_id, contact_id) VALUES (999,999,888);")
    @conn.exec("INSERT into messages_lists (id, message_id, list_id) VALUES (999,999,999);")
    @conn.exec("INSERT into smtp_relays (id, hostname, public_ips, private_ip) VALUES (999,'A','{10.10.10.10}','11.11.11.11');")
    @conn.exec("INSERT into delivery_status (id, name) VALUES (0,'aa')")
    @conn.exec("INSERT into deliveries (id, message_id, contact_id, smtp_relay_id, email) VALUES (999,999,888,999,'aaa@gmail.com');")
    @conn.exec("INSERT into urls (id,message_id,url) VALUES (777,999,'http://mailee.me?name=john&code=123')")
  end

  def delete_delivery
    @conn.exec("DELETE FROM accesses WHERE message_id = 999")
    @conn.exec("DELETE FROM urls WHERE id = 777")
    @conn.exec("DELETE FROM deliveries WHERE id in (999,998,997)")
    @conn.exec("DELETE FROM smtp_relays WHERE id = 999")
    @conn.exec("DELETE FROM messages_lists WHERE id = 999")
    @conn.exec("DELETE FROM lists_contacts WHERE id = 999")
    @conn.exec("DELETE FROM lists WHERE id = 999")
    @conn.exec("DELETE FROM contacts WHERE id = 888")
    @conn.exec("DELETE FROM messages WHERE id = 999")
    @conn.exec("DELETE FROM clients WHERE id = 999")
    @conn.exec("DELETE FROM delivery_status WHERE id = 0")
  end

end
