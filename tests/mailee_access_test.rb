require 'eventmachine'
require 'eventmachine-tail'
require './src/mailee.rb'
require './tests/helper.rb'

class MaileeAccessTest < Test::Unit::TestCase

  def setup
    setup_files
    @conn = PGconn.open(@config['database'])
    create_delivery
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
