class Mailee::Click < Mailee::Stats
  def insert_into_db(l)
    @conn.exec(
      "SELECT insert_click($1,$2,$3,$4,$5,$6)",
      [l[0],l[1],l[2],Mailee::Stats.parse_id(l[3]),Mailee::Stats.parse_url(l[3]),Mailee::Stats.parse_key(l[3])]
    )
  end

  def self.query_type
    'Click'
  end
end
