require 'rubygems'
require 'sinatra/base'
require 'twitter_oauth'
require 'haml'

##http://github.com/banux/twitter_oauth/blob/159f46d45e93f8a211c7629c44afb8bba95910c5/lib/twitter_oauth/lists.rb
module TwitterOAuth

  class User
    attr_accessor :client,:info
    
    def initialize client,info
      self.client = client
      self.info = info
    end
    
    def lists
      p screen_name
      client.get_lists(screen_name)['lists'].map {|list| List.new client, list}
    end
    
    def list list_name
      List.new client.get_list(screen_name, list_name)
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
 
##

#
# borrowed heavily from http://github.com/moomerman/sinitter
#
class TwitterListManager < Sinatra::Base

  configure do
    set :sessions, true
    set :views, File.dirname(__FILE__) + '/views'

    @@config = {
      :consumer_key=>ENV['TWITTER_OAUTH_KEY'],
      :consumer_secret=>ENV['TWITTER_OAUTH_SECRET']
    }
    @@callback = ENV['TWITTER_OAUTH_CALLBACK']
  end

  before do
    @client = TwitterOAuth::Client.new(
      @@config.merge(
        :token  => session[:access_token],
        :secret => session[:secret_token]
      )
    )
    @user = TwitterOAuth::User.new @client, session[:user] if session[:user]
    @rate_limit_status = @client.rate_limit_status
    
    redirect '/' unless @user
  end

  get '/' do
    redirect '/lists' if @user
    '<a href=/connect>connect through twitter</a>'
  end

  get '/lists' do
    @lists = @user.lists
    p 'after lists'
    haml :lists
  end

  get '/connect' do
    request_token = @client.authentication_request_token( :oauth_callback=> ENV['TWITTER_OAUTH_CALLBACK'])
    session[:request_token] = request_token.token
    session[:request_token_secret]=request_token.secret
    redirect request_token.authorize_url.gsub('authorize','authenticate')
  end

  get '/auth' do
    begin
      @access_token = @client.authorize(
          session[:request_token],
          session[:request_token_secret],
          :oauth_verifier => params[:oauth_verifier]
       )
    rescue OAuth::Unauthorized => e
     p e
    end
    if @client.authorized?
      session[:access_token] = @access_token.token
      session[:secret_token] = @access_token.secret
      session[:user] = @client.info
      redirect '/lists'
    else
      status 403
      'Not Authed'
    end
  end
  
  get '/disconnect' do
    session[:user] = nil
    session[:request_token] = nil
    session[:request_token_secret] = nil
    session[:access_token] = nil
    session[:secret_token] = nil
    redirect '/'
  end
  
  post '/update_list' do
  end
end
