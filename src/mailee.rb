class Mailee
  require 'time'
  require 'pg'
  require 'uri'
  require 'cgi'
  
  class Sync 
    def initialize(path, config, klass)
      @path = path
      @config = config
      @klass = klass
      @conn = PGconn.open(@config['database'])      
      @m = klass.new(path)
      $0 = "Mailee Log Watcher - Sync #{klass.query_type}" 
    end

    def run
      @initial_size = `wc -l #{@path}`.split(' ').first.to_i
      @io = File.open(@path,'r')
      @initial_size.times do
        begin
          line = @io.gets 
          parsed = @klass.parse_line(line)
          @m.insert_into_db(parsed)
        rescue 
          nil
        end
      end
    end
  end
  
  class Stats < EventMachine::FileTail
    
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

  class Access < Stats

    def insert_into_db(l)
      #unique_sql = unique ? "NOT EXISTS (SELECT 1 FROM accesses WHERE created_at = to_timestamp('#{l[0]}') AND message_id = d.message_id AND contact_id = d.contact_id AND d.id = #{Click.parse_id(l[3])} AND type = 'View')" : "true"
      #@conn.exec("
        #INSERT INTO accesses (message_id, contact_id, created_at, ip, user_agent_string, type) 
        #SELECT message_id, contact_id, to_timestamp('#{l[0]}'), '#{l[1]}', '#{@conn.escape_string(l[2])}', 'View' 
        #FROM deliveries d 
        #WHERE id = #{Access.parse_id(l[3])} 
        #AND NOT test
        #AND #{unique_sql}
        #")
        @conn.exec(
          "SELECT insert_access($1,$2,$3,$4)",
          [l[0].to_f,l[1],l[2],Stats.parse_id(l[3])]
        )
    end

    def self.query_type
      'View'
    end

  end

  class Click < Stats
    def insert_into_db(l)
      @conn.exec(
        "SELECT insert_click($1,$2,$3,$4,$5,$6)",
        [l[0],l[1],l[2],Stats.parse_id(l[3]),Stats.parse_url(l[3]),Stats.parse_key(l[3])]
      )
    end

    def self.query_type
      'Click'
    end
  end


end
