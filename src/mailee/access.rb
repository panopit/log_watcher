class Mailee::Access < Mailee::Stats

  def insert_into_db(l)
      @conn.exec(
        "SELECT insert_access($1,$2,$3,$4)",
        [l[0].to_f,l[1],l[2],Mailee::Stats.parse_id(l[3])]
      )
  end

  def self.query_type
    'View'
  end

end
