class HandlerClass
  require './src/handler.rb'
  include Handler 
end

class HandlerTest < Test::Unit::TestCase
  
  def initialize_handler
    HandlerClass.new({
      :config => {
        "path" => "/tmp/foo", 
        "patterns" => {
          "a" => {
            "regex" => "a", 
            "callback" => "Callbacks.test_matches_a match"
          },
          "aaa" => {
            "regex" => "aaa",
            "callback" => "Callbacks.test_matches_aaa match"
          }
        } 
      }
    })
  end  
  
  def test_initializer      
    # test you cannot initialize a handler without a config
    assert_raise(RuntimeError){HandlerClass.new}
    assert HandlerClass.new({:config => 'thing'})
  end
  
  def test_receive_data
    FileUtils.rm %w( test_matches_a.log test_matches_aaa.log ), :force => true
    
    h = initialize_handler
    h.receive_data 'aaaaaa'
    assert_equal ["a\n", "a\n", "a\n", "a\n", "a\n", "a\n"], File.open("test_matches_a.log").readlines
    FileUtils.rm 'test_matches_a.log'
    assert_equal ["aaa\n","aaa\n"], File.open("test_matches_aaa.log").readlines
    FileUtils.rm 'test_matches_aaa.log'
        
    h = initialize_handler
    h.receive_data 'bbbbbbb'
    assert_equal false, (File.exists?('test_matches_aaa.log') or File.exists?('test_matches_a.log'))
  end

end
