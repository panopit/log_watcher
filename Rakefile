# Rakefile com execucao de testes
task :default => [:test, :doc] do 
end

task :test do 
  require 'rake/runtest'

  yaml = '---
  database:
    host: localhost
    port: 5432
    dbname: mailee_test
    user: log_watcher
    password: 1234
    '
  FileUtils.mv('config.yml','original.config.yml')
  File.open('config.yml', 'w'){|f| f.write yaml  }
  FileUtils.touch("test.log")

  #pid = fork do
    #puts "PROCESSO filho" 
    #require 'src/watcher'
  #end
  #puts "PROCESSO PAI #{pid}" 
  
  verbose(false) do
    Rake.run_tests 'tests/*_test.rb'
  end
  #Process.kill pid    
  #FileUtils.rm('config.yml')
  #FileUtils.rm('test.log')
  #FileUtils.mv('original.config.yml','config.yml')  
end
