class Callbacks
  
  def self.puts_result match
    puts "PATTERN MATCHED: #{match}"
  end
  
  def self.test_matches_a match
    `echo #{match} >> test_matches_a.log `
  end
  
  def self.test_matches_aaa match
    `echo #{match} >> test_matches_aaa.log `
  end
  
end