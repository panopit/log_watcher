class Mailee::Click < Mailee::Stats
  def insert_into_db(line)
    return unless Mailee::Stats.valid_path?(line[3])
    user_agent = UserAgentInfo.parse(line[2])
    geokit = Mailee::Stats.geocode(line[1],@geoip)

    access_id, contact_id = insert_with_geoinfo(line, geokit, user_agent)

    if access_id
      @conn.exec("UPDATE contacts SET contact_status_id = 4 
        WHERE id = $1 AND contact_status_id in (-5,0,2,3);
      ", [contact_id])
    end
    
    Mailee::Stats.update_contact_geoinfo contact_id, geokit, @conn if contact_id and geokit
    
    {access_id: access_id, contact_id: contact_id}
  end

  def self.query_type
    'Click'
  end
 
  def insert_with_geoinfo l, geokit, user_agent
    access_id, contact_id = @conn.exec(
      "
      INSERT INTO accesses (contact_id, url_id, message_id, created_at, ip, user_agent_string, type, country_code, city, latitude, longitude, region, user_agent_name, user_agent_version, os, os_version, country_code3)
      SELECT d.contact_id, u.id, d.message_id, to_timestamp($1), $2, $3, 'Click', $7, $8, $9, $10, $11, $12, $13, $14, $15, $16
      FROM deliveries d
      JOIN urls u ON u.message_id = d.message_id 
      WHERE d.id = $4
      AND (
        remove_analytics_line($5) = u.url
        OR replace(remove_analytics_line($5),'?','/?') = u.url
        OR replace(remove_analytics_line($5),'/?','?') = u.url
        )
      AND auth_key(d.id, d.email) = $6
      AND NOT d.test
      AND NOT EXISTS  
        (SELECT 1 FROM accesses a 
        WHERE created_at = to_timestamp($1) 
        AND a.message_id = d.message_id 
        AND a.contact_id = d.contact_id
        AND d.id = $4
        AND a.url_id = u.id
        AND type = 'Click')
      RETURNING accesses.id, accesses.contact_id
      ",
      [l[0],l[1],l[2],Mailee::Stats.parse_id(l[3]),Mailee::Stats.parse_url(l[3]),Mailee::Stats.parse_key(l[3]),geokit[:country_code], geokit[:city], geokit[:latitude], geokit[:longitude], geokit[:region], user_agent.agent.name, user_agent.agent.version, user_agent.os.name, user_agent.os.version, geokit[:country_code3]]
    )[0].values rescue nil
  end

end
