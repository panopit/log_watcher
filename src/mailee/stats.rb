class Mailee::Stats < EventMachine::FileTail
  require 'geokit'

  def initialize(path, startpos=-1)
    super(path, startpos)
    puts "Tailing #{path}"
    @buffer = BufferedTokenizer.new
    @config = YAML.load_file('config.yml')
    raise 'Could not load config.yml' unless @config
    @conn = PGconn.open(@config['database'])
  end

  def receive_data(data)
    @buffer.extract(data).each do |line|
      begin
        insert_into_db(Mailee::Stats.parse_line(line))
      rescue => e
        puts "#{Time.now} EXCEPTION:"
        puts e.inspect
        puts e.backtrace.inspect
        puts "LINE: #{line.inspect}"
      end
    end
  end

  def self.parse_line(line)
    # 1315863905.666|192.168.56.1|GET /go/view/24234234 HTTP/1.1|curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5
    l = line.encode("UTF-8", {invalid: :replace, replace: '?'} ).split('|')
    
    # [epoch, ip, user_agent, url]
    [l[0], l[1], l[3], l[2].split(' ')[1]]
  end

  def self.parse_id(path)
    path.split('/')[3].to_i
  end

  def self.parse_url(path)
    begin
      u = URI.parse(path)
    rescue
      u = URI.parse(path.split('%2F%3Futm_source')[0])
    end
    CGI::parse(u.query)["url"][0]
  end

  def self.parse_key(path)
    CGI::parse(path.split('?')[1])["key"][0]
  end

  def self.valid_path?(path)
      u = URI.parse(path)
    not u.query.nil?
  end
  # URI.parse(path.split('%2F%3Futm_source')[0])
  def self.geocode(ip)
    Geokit::Geocoders::GeoPluginGeocoder.do_geocode(ip)
  end
  def self.update_contact_geoinfo contact_id, geokit, conn
    conn.exec("UPDATE contacts SET latitude = $1, longitude = $2 WHERE id = $3",
              [geokit.lat, geokit.lng, contact_id]
              )
  end
end
