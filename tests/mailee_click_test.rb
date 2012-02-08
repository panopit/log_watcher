require 'test/unit'

class MaileeClickTest < Test::Unit::TestCase
  

  def setup
    setup_files
    @conn = PGconn.open(@config['database'])
    create_delivery
  end

  def teardown
    delete_delivery
    remove_files
  end

  def test_should_insert_click_line
    result = ["1315941774.461","192.168.56.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1","/go/click/999?key=fa2492&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123"]    
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

  def test_should_insert_click_and_record_useragentinfo
    result = ["1315941774.461","192.168.56.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1","/go/click/999?key=fa2492&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123"]    
    @m = Mailee::Click.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT * FROM accesses WHERE message_id = 999")[0]
    assert_equal r["user_agent_name"], "Chrome"
    assert_equal r["user_agent_version"], "13"
    assert_equal r["os"], "MacOS"
    assert_equal r["os_version"], "Lion"
  end

  def test_should_insert_click_and_record_useragentinfo_and_geoinfo
    result = ["1315941774.461","8.8.8.8","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1","/go/click/999?key=fa2492&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123"]    
    @m = Mailee::Click.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT * FROM accesses WHERE message_id = 999")[0]
    assert_equal r["user_agent_name"], "Chrome"
    assert_equal r["user_agent_version"], "13"
    assert_equal r["os"], "MacOS"
    assert_equal r["os_version"], "Lion"
    assert_equal "Mountain View", r["city"]
    assert_equal 37.4192008972168, r["latitude"].to_f
    assert_equal -122.05740356445312312, r["longitude"].to_f
    assert_equal "US", r["country_code"]
    assert_equal "USA", r["country_code3"]
    assert_equal "CA", r["region"]
  end
  def test_should_insert_click_and_record_its_geo_info
    result = ["1315941774.461","8.8.8.8","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1","/go/click/999?key=fa2492&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123"]    
    @m = Mailee::Click.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT * FROM accesses WHERE message_id = 999")[0]
    assert_equal "Mountain View", r["city"]
    assert_equal 37.4192008972168, r["latitude"].to_f
    assert_equal -122.05740356445312312, r["longitude"].to_f
    assert_equal "US", r["country_code"]
    assert_equal "CA", r["region"]
  end

  def test_should_insert_click_and_update_contact_info
    result = ["1315941774.461","8.8.8.8","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1","/go/click/999?key=fa2492&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123"]    
    @m = Mailee::Click.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT * FROM contacts WHERE id = 888")[0]
    assert_equal 37.4192008972168, r["latitude"].to_f
    assert_equal -122.05740356445312312, r["longitude"].to_f
  end
  

  def test_should_insert_click_and_update_contact_status
    result = ["1315941774.461","192.168.56.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1","/go/click/999?key=fa2492&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123"]    
    @m = Mailee::Click.new("test.log")
    contact_id = @m.insert_into_db(result)[:contact_id]
    r = @conn.exec("SELECT * FROM contacts WHERE id = #{contact_id}")[0]
    assert_equal 4, r["contact_status_id"].to_i
  end

  def test_should_not_insert_twice_the_same_click_line
    result = ["1315941774.461","192.168.56.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1","/go/click/999?key=fa2492&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123"]    
    @m = Mailee::Click.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]["count"]    
    assert_equal 1, r.to_i
    @m.insert_into_db(result)
    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]["count"]    
    assert_equal 1, r.to_i
  
  end
  
  def test_should_not_insert_click_from_test
    @conn.exec("UPDATE deliveries SET test = true WHERE id = 999")    
    result = ["1315941774.461","192.168.56.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1","/go/click/999?key=3123&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123"]    
    @m = Mailee::Click.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]
    assert_equal 0,r["count"].to_i
  end

  def test_should_not_raise_a_nil_line
    result = ["1315941774.461","192.168.56.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1","/go/click/999"]        
    @m = Mailee::Click.new("test.log")
    @m.insert_into_db(result)
  end

end
