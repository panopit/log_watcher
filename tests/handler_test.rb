class WatcherTest < Test::Unit::TestCase

  def test_catch
    
=begin
        File.open('tmp.log', 'w+'){|f| f.write "escrevo linha que deve ser copiada pelo callback" }
        File.open('arquivo_criado_pelo_callback'){|f| s = r.read }
        assert_equal s, "escrevo linha que deve ser copiada pelo callback"
        Handler aqui iniciamos o watcher
=end    
  end
end