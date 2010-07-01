# Rakefile com execucao de testes
task :default => [:test, :doc] do 
end

task :test do 
  require 'rake/runtest'
  verbose(false) do
    Rake.run_tests 'tests/*test.rb'
  end
end

task :doc do 
  sh "rdoc src/maileed.rb"
end