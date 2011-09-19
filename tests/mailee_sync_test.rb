require 'eventmachine'
require 'eventmachine-tail'
require './src/mailee.rb'
require './tests/helper.rb'


class MaileeSyncTest < Test::Unit::TestCase

  def setup
    setup_files
    @conn = PGconn.open(@config['database'])
    create_delivery
  end

  def teardown
    delete_delivery
    remove_files
  end



  def test_should_sync_files
    results = []
    (989..999).each do |i|
      results << ["1315941#{i}.461","192.168.56.1","GET /go/view/#{i} HTTP/1.1","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1"].join('|')    
      @conn.exec("INSERT into deliveries (id, message_id, contact_id, smtp_relay_id, email) VALUES (#{i},999,888,999,'aaa@gmail.com');") rescue nil
    end

    File.open("sync.log",'w') {|f| f.write(results[8..9].join("\n"))}
    File.open("sync.log.1",'w') {|f| f.write(results[5..7].join("\n"))}
    File.open("sync.log.2",'w') {|f| f.write(results[1..4].join("\n"))}
    File.open("sync.log.3",'w') {|f| f.write(results[0])}
    
    `gzip -f sync.log.2`
    `gzip -f sync.log.3`

    Mailee::Access.new('sync.log').insert_into_db(Mailee::Access.parse_line(results[1]))

    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]["count"].to_i
    assert_equal 1, r
    
    last_access = @conn.exec("SELECT EXTRACT (epoch FROM created_at) FROM accesses WHERE type='#{Mailee::Access.query_type}' ORDER BY created_at desc LIMIT 1")[0]["date_part"]
    m = Mailee::Sync.new('sync.log', @config, last_access, Mailee::Access)
    m.run

    r = @conn.exec("SELECT count(*) FROM accesses WHERE message_id = 999")[0]["count"].to_i
    FileUtils.rm Dir.glob('sync.log*')

  end


end
