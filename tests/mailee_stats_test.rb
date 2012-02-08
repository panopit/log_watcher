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


  def test_should_verify_valid_paths
    p1 = "http://mailee.me/go/click/999?key=3123&url=http%3A//mailee.me%3Fname%3Djohn%26code%3D123"
    p2 = "http://mailee.me/go/click/999"
    assert_equal true, Mailee::Stats.valid_path?(p1)
    assert_equal false, Mailee::Stats.valid_path?(p2)
    
    path = "/go/click/93280032?xrl=o4rq00&hey=uggc://jjj.phcbafivc.pbz.oe/fnyinqbe/bsregnfQvn?hgz_fbhepr=Fvgr&hgz_zrqvhz=Znvyrr.zr&hgz_pnzcnvta=Bsregn&hgz_pbagrag=Fbeirgr%2p+Ebqvmvb%2p+Pbzovanqb"
    assert_equal false, Mailee::Stats.valid_path?(path)
  end

  def test_should_rescue_invalid_urls
    path = "/go/click/133233021?key=af298b&amp;url=http%3A%2F%2Forbirh.wordpress.com%2F2011%2F10%2F26%2Fprogramacao-de-janeiro%2F%3Futm_source%3DMailee%26utm_medium%3Demail%26utm_campaign%3DPrograma%25C3%25A7%25C3%25A3o%2B01%252F2012%26utm_term%3"
    assert_equal 133233021, Mailee::Stats.parse_id(path)
    assert_equal 'http://orbirh.wordpress.com/2011/10/26/programacao-de-janeiro/', Mailee::Stats.parse_url(path)

  end

  def test_should_parse_strange_urls
    path = "/go/click/91985531?key=f8c53c&url=http%3A%2F%2Fwww.grupoa.com.br%2Fsite%2Fexatas-sociais-e-aplicadas%2F2%2F99%2F100%2Fdesign.aspx%3Futm_source%3DMailee%26utm_medium%3Demail%26utm_campaign%3D2011%252F10%2B%257C%2BEMM%26utm_term%3"
    assert_equal 91985531, Mailee::Stats.parse_id(path)
    assert_equal "http://www.grupoa.com.br/site/exatas-sociais-e-aplicadas/2/99/100/design.aspx", Mailee::Stats.parse_url(path)
    assert_equal true, Mailee::Stats.valid_path?(path)

    path = "/go/click/120583838?key=93c1dc&amp;url=http%3a%2f%2fwww.mailee.me%2f%3futm_source%3dmailee%26utm_medium%3demail%26utm_campaign%3dbits%2b2011%26utm_term%3d%26utm_content%3d2414s%2b-%2b08%252f08%2b10%252f08%2b26%252f10%2b23%"
    assert_equal 120583838, Mailee::Stats.parse_id(path)
    assert_equal "http://www.mailee.me/", Mailee::Stats.parse_url(path)
    assert_equal true, Mailee::Stats.valid_path?(path)
  end

  def test_should_return_geocode_info
    @geoip = GeoIP::City.new('GeoLiteCity.dat', :filesystem, true)       
    r = Mailee::Stats.geocode('8.8.8.8', @geoip)
    assert_equal "Mountain View", r[:city]
    assert_equal "CA", r[:region]
    assert_equal 37.4192008972168, r[:latitude]
    assert_equal -122.05740356445312, r[:longitude]
    assert_equal "US", r[:country_code]
    assert_equal "USA", r[:country_code3]
  end

  def test_should_insert_access_information
  end

end
