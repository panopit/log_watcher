class Mailee::Sync 
  def initialize(path, config, last_epoch, klass)
    @path = path
    @config = config
    @klass = klass
    @conn = PGconn.open(@config['database'])      
    @m = klass.new(path)
    @last_epoch = last_epoch.to_f
  end

  def run
    $0 = "mailee log watcher - sync #{@klass.query_type}" 
    @initial_size = `wc -l #{@path}`.split(' ').first.to_i
    check_old_files
    @io = File.open(@path,'r')
    @initial_size.times do
      begin
        line = @io.gets 
        parsed = @klass.parse_line(line)
        @m.insert_into_db(parsed)
      rescue => e
        puts e.inspect
      end
    end
  end

  def check_old_files
    index = 1
    loop do
      current_path = (index == 1 ? "#{@path}.1" : "#{@path}.#{index}.gz")
      break if parse_file(current_path, open_file(index, current_path))
      index += 1
    end
  end

  def parse_file(current_path,io)
    return true unless io
    m = @klass.new(current_path)
    stop_sync = false
    parsed = @klass.parse_line(io.gets)
    m.insert_into_db(parsed)
    stop_sync = true if parsed[0].to_f <= @last_epoch
    while line = io.gets do
      begin
        parsed = @klass.parse_line(line)
        m.insert_into_db(parsed) unless parsed[0].to_f <= @last_epoch
      rescue => e
        puts e.inspect
      end
    end
    stop_sync 
  end

  def open_file(index,current_file)
    if index == 1
      return File.open(current_file,'r') rescue false
    else
      return Zlib::GzipReader.new(File.open(current_file,'r')) rescue false
    end
  end

end
