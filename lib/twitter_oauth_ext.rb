

##http://github.com/banux/twitter_oauth/blob/159f46d45e93f8a211c7629c44afb8bba95910c5/lib/twitter_oauth/lists.rb

##
module TwitterOAuth

  class User
    attr_accessor :client,:info
    
    def initialize client,info
      self.client = client
      self.info = info
    end
    
    def lists
      client.get_lists(screen_name)['lists'].map {|list| List.new client, list}
    end
    
    def list list_name
      List.new client, client.get_list(screen_name, list_name)
    end
    
    def method_missing method, *args
      info[method.to_s]
    end
  end
  
  
  class List
    
    attr_accessor :client,:info
    #info here is the result of client.get_list
    def initialize client,info
      self.info = info
      self.client = client
    end
    
    def add_member screen_name
      client.add_member_to_list user['screen_name'],slug, client.show(screen_name)["id"]
    end
    
    def remove_member screen_name
      client.remove_member_from_list user['screen_name'],slug, client.show(screen_name)["id"]
    end
    
    def members
      client.list_members(user['screen_name'], slug)['users'].map{|user| User.new(client,user)}
    end
    
    def method_missing method, *args
      info[method.to_s]
    end
    
  end
end
 
