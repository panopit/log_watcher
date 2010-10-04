# Rakefile com execucao de testes
task :default => [:test, :doc] do 
end

task :test do 
  require 'rake/runtest'

=begin
  yaml = '---
  test:
    path: /tmp/foo
    patterns:
      one: 
        regex: a
        callback: puts "pattern one" 
      two:
        regex: b
        callback: puts "pattern two"'
  FileUtils.mv('config.yml','original.config.yml')
  File.open('config.yml', 'w'){|f| f.write yaml  }
  File.open('tmp.log', 'w'){|f| f.write "" }
  
  pid = fork do
    puts "PROCESSO filho" 
    require 'src/watcher'
  end
  puts "PROCESSO PAI #{pid}" 
=end
  
  verbose(false) do
    Rake.run_tests 'tests/*_test.rb'
  end
=begin  
  Process.kill pid    
  FileUtils.rm('confg.yml')
  FileUtils.rm('tmp.log')
  FileUtils.mv('original.config.yml','config.yml')  
=end
end