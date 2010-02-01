require 'rubygems'
require 'sinatra/base'
require 'twitter_oauth'
require 'haml'

require 'lib/twitter_oauth_ext'

#
# Started with http://github.com/moomerman/sinitter,
# moomerman's example of how to use twitter_oauth,
# and modified it.
#
# 
class TwitterListManager < Sinatra::Base

  configure do
  
    enable :methodoverride

    set :views, File.dirname(__FILE__) + '/views'

    enable :sessions
    set :twitter_oauth_config, 
      :key      =>ENV['TWITTER_OAUTH_KEY'],
      :secret   =>ENV['TWITTER_OAUTH_SECRET'],
      :callback => ENV['TWITTER_OAUTH_CALLBACK']
  end

  helpers do
    def login_required
      setup_client
      
      @user = TwitterOAuth::User.new(@client, session[:user]) if session[:user]
      
      @rate_limit_status = @client.rate_limit_status
      
      redirect '/login' unless @user
    end
    
    def setup_client
      @client ||= TwitterOAuth::Client.new(
        :consumer_secret => options.twitter_oauth_config[:secret],
        :consumer_key => options.twitter_oauth_config[:key],
        :token  => session[:access_token],
        :secret => session[:secret_token]
      )
    end
    
    def get_request_token
      setup_client
      @client.authentication_request_token(:oauth_callback=>options.twitter_oauth_config[:callback])
    end
    
    def get_access_token
      setup_client
      
      begin
        @client.authorize(
            session[:request_token],
            session[:request_token_secret],
            :oauth_verifier => params[:oauth_verifier]
         )
      rescue OAuth::Unauthorized => e
        nil
      end
    end
    
    def redirect_to_twitter_auth_url
      request_token = get_request_token
    
      session[:request_token] = request_token.token
      session[:request_token_secret]= request_token.secret
    
      redirect request_token.authorize_url.gsub('authorize','authenticate')
    end
    
    def authenticate!
      access_token = get_access_token
    
      if @client.authorized?
        session[:access_token] = access_token.token
        session[:secret_token] = access_token.secret
        session[:user] = @client.info

        session[:user]
      else
        nil
      end
    end
    
    def clear_oauth_session
      session[:user] = nil
      session[:request_token] = nil
      session[:request_token_secret] = nil
      session[:access_token] = nil
      session[:secret_token] = nil
    end
  end

  get '/login' do
    redirect '/' if @user
    
    haml :login
  end

  get '/' do
    login_required
    
    @lists = @user.lists.sort{|a,b| a.name <=> b.name }
    
    haml :lists
  end

  put '/:list_name' do
    login_required
    
    @list = @user.list params[:list_name]
    pass unless @list
    
    if params['list']['remove_members']
      @list.remove_members params['list']['remove_members'].keys
    end
    
    unless !params['list']['new_members'] || params['list']['new_members'].empty?
      @list.add_members params['list']['new_members'].split
    end
    
    redirect '/'
  end


  post '/new_list' do
    login_required
    
    @list = @user.new_list params['list']['name'], params['list']['private'] ? {:mode=>'private'} : {}
    
    @list.add_members params['list']['members'].split unless params['list']['members'].empty?
    
    redirect '/'
  end
  
  delete '/:list_name' do
    login_required
    
    @user.destroy_list params[:list_name]
    
    redirect '/'
  end
  
  get '/connect' do
    redirect_to_twitter_auth_url
  end

  get '/auth' do
    if authenticate!
      redirect '/'
    else
      status 403
      'Not Authenticated'
    end
  end
  
  get '/logout' do
    clear_oauth_session
    redirect '/login'
  end

end
