
  def setup_files
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
    @config = YAML.load(yaml)
    @config['database']['user'] = 'mailee'
  end

  def remove_files
    FileUtils.rm('config.yml')
    FileUtils.rm('test.log')
    FileUtils.mv('original.config.yml','config.yml')  
  end

  def create_delivery
   @conn.exec("INSERT into clients (id,name,subdomain) VALUES ('999','acme','acme')")
    @conn.exec("INSERT into messages (id, client_id, title, subject, from_name, from_email, reply_email) VALUES ('999','999','A','A','A','aaa@softa.com.br','aaa@softa.com.br');")
    @conn.exec("INSERT into contact_status (id,name) VALUES (0,'a'),(-5,'b'),(2,'c'),(3,'d'),(4,'e');") rescue nil
    @conn.exec("INSERT into contacts (id, client_id, email) VALUES (888,999, 'aaaaa@softa.com.br');")
    @conn.exec("INSERT into lists (id, client_id, name) VALUES (999,999,'a');")
    @conn.exec("INSERT into lists_contacts (id, list_id, contact_id) VALUES (999,999,888);")
    @conn.exec("INSERT into messages_lists (id, message_id, list_id) VALUES (999,999,999);")
    @conn.exec("INSERT into smtp_relays (id, hostname, public_ips, private_ip) VALUES (999,'A','{10.10.10.10}','11.11.11.11');")
    @conn.exec("INSERT into delivery_status (id, name) VALUES (0,'aa')")
    @conn.exec("INSERT into deliveries (id, message_id, contact_id, smtp_relay_id, email) VALUES (999,999,888,999,'aaa@gmail.com');")
    @conn.exec("INSERT into urls (id,message_id,url) VALUES (777,999,'http://mailee.me?name=john&code=123')")
  end

  def delete_delivery
    @conn.exec("DELETE FROM accesses WHERE message_id = 999")
    @conn.exec("DELETE FROM urls WHERE id = 777")
    @conn.exec("DELETE FROM deliveries WHERE message_id = 999")
    @conn.exec("DELETE FROM smtp_relays WHERE id = 999")
    @conn.exec("DELETE FROM messages_lists WHERE id = 999")
    @conn.exec("DELETE FROM lists_contacts WHERE id = 999")
    @conn.exec("DELETE FROM lists WHERE id = 999")
    @conn.exec("DELETE FROM contacts WHERE id = 888")
    @conn.exec("DELETE FROM messages WHERE id = 999")
    @conn.exec("DELETE FROM contact_status")
    @conn.exec("DELETE FROM clients WHERE id = 999")
    @conn.exec("DELETE FROM delivery_status WHERE id = 0")
  end
