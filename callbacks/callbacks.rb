class Callbacks
  
  def self.test_matches_a match
    `echo #{match} >> test_matches_a.log `
  end
  
  def self.test_matches_aaa match
    `echo #{match} >> test_matches_aaa.log `
  end
  
  def self.debug match
    puts match.inspect
  end
  
end