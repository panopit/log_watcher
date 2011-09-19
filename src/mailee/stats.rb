class Mailee::Stats < EventMachine::FileTail
  
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
      insert_into_db(Stats.parse_line(line))
    end
  end

  def self.parse_line(line)
    # 1315863905.666|192.168.56.1|GET /go/view/24234234 HTTP/1.1|curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5
    l = line.split('|')
    
    # [epoch, ip, user_agent, url]
    [l[0], l[1], l[3], l[2].split(' ')[1]]
  end

  def self.parse_id(path)
    path.split('/')[3].to_i
  end

  def self.parse_url(path)
    URI.unescape(CGI::parse(path)["url"][0])
  end

  def self.parse_key(path)
    CGI::parse(path.split('?')[1])["key"][0]
  end

end
