class MaileeStatsTest < Test::Unit::TestCase

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

  def test_should_parse_key
    assert_equal '3123', Mailee::Stats.parse_key('/go/click/24234234?key=3123&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123')
  end


  def test_should_parse_click_line
    result = ["1315941774.461","192.168.56.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1","/go/click/24234234?key=3123&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123"]
    assert_equal result, Mailee::Click.parse_line("1315941774.461|192.168.56.1|GET /go/click/24234234?key=3123&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123 HTTP/1.1|Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1")
  end
end
