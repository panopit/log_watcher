require 'eventmachine'
require 'eventmachine-tail'
require './src/mailee.rb'
require './tests/helper.rb'
require 'mocha'
require 'ostruct'

class MaileeAccessTest < Test::Unit::TestCase

  def setup
    setup_files
    @conn = PGconn.open(@config['database'])
    create_delivery
    geokit = OpenStruct.new(country_code: nil, city: nil, lat: nil, lng: nil, state:nil )
    Mailee::Stats.expects(:geokit).with('192.168.56.1').returns(geokit).at_least(0)
    geokit2 = OpenStruct.new(country_code: 'US', city: 'Mountain View', lat: 37.419200897217, lng: -122.05740356445, state: 'CA' )
    Mailee::Stats.expects(:geokit).with('8.8.8.8').returns(geokit2).at_least(0)
    
  end
  def teardown
    delete_delivery
    remove_files
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
  
  def test_should_insert_access_and_record_useragentinfo
    result = ["1315863905.666","192.168.56.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.77 Safari/535.7","/go/view/999"]    
    @m = Mailee::Access.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT * FROM accesses WHERE message_id = 999")[0]
    assert_equal r["user_agent_name"], "Chrome"
    assert_equal r["user_agent_version"], "16"
    assert_equal r["os"], "MacOS"
    assert_equal r["os_version"], "Lion"
  end

  def test_should_insert_access_and_record_its_geo_info
    result = ["1315863906.666","8.8.8.8","curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5","/go/view/999"]    
    @m = Mailee::Access.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT * FROM accesses WHERE message_id = 999")[0]
    assert_equal "Mountain View", r["city"]
    assert_equal 37.419200897217, r["latitude"].to_f
    assert_equal -122.05740356445, r["longitude"].to_f
    assert_equal "US", r["country_code"]
    assert_equal "CA", r["region"]
  end

  def test_should_insert_access_and_record_useragentinfo_and_geoinfo
    result = ["1315863905.666","8.8.8.8","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.77 Safari/535.7","/go/view/999"]    
    @m = Mailee::Access.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT * FROM accesses WHERE message_id = 999")[0]
    assert_equal r["user_agent_name"], "Chrome"
    assert_equal r["user_agent_version"], "16"
    assert_equal r["os"], "MacOS"
    assert_equal r["os_version"], "Lion"
    assert_equal "Mountain View", r["city"]
    assert_equal 37.419200897217, r["latitude"].to_f
    assert_equal -122.05740356445, r["longitude"].to_f
    assert_equal "US", r["country_code"]
    assert_equal "CA", r["region"]
  end
  
  def test_should_insert_access_and_update_contact_geoinfo
    result = ["1315863906.666","8.8.8.8","curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5","/go/view/999"]    
    @m = Mailee::Access.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT * FROM contacts WHERE id = 888")[0]
    assert_equal 37.419200897217, r["latitude"].to_f
    assert_equal -122.05740356445, r["longitude"].to_f
  end

  def test_should_insert_access_and_update_contact_status
    result = ["1315863905.666","192.168.56.1","curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5","/go/view/999"]    
    @m = Mailee::Access.new("test.log")
    contact_id = @m.insert_into_db(result)[:contact_id]
    r = @conn.exec("SELECT * FROM contacts WHERE id = #{contact_id}")[0]
    assert_equal 4, r["contact_status_id"].to_i
  end

  def test_should_not_insert_duplicate_values
    result = ["1315863905.666","192.168.56.1","curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5","/go/view/999"]    
    @m = Mailee::Access.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]["count"]
    assert_equal 1, r.to_i
    @m.insert_into_db(result)
    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]["count"]
    assert_equal 1, r.to_i
  end

  def test_should_not_insert_access_from_test
    @conn.exec("UPDATE deliveries SET test = true WHERE id = 999")
    result = ["1315863905.666","192.168.56.1","curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5","/go/view/999"]    
    @m = Mailee::Access.new("test.log")
    @m.insert_into_db(result)
    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")
    assert_equal 0, r[0]["count"].to_i
  end

end
