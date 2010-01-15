require 'rubygems'
require 'sinatra/base'
require 'twitter_oauth'
require 'haml'

require 'lib/twitter_oauth_ext'

#
# borrows parts of http://github.com/moomerman/sinitter,
# moomerman's example of how to use twitter_oauth
#
class TwitterListManager < Sinatra::Base

  configure do
  
    enable :methodoverride 
  
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
    
    redirect '/login' unless @user || ['/login','/auth','/connect'].include?(request.path_info)
  end

  get '/login' do
    redirect '/' if @user
    haml :login
  end

  get '/' do
    @lists = @user.lists.sort{|a,b|a.name<=>b.name}
    haml :lists
  end

  put '/:list_name' do
    @list = @user.list params[:list_name]
    pass unless @list
    if params['list']['remove_members']
      params['list']['remove_members'].each do |screen_name,_|
        @list.remove_member screen_name
      end
    end
    unless !params['list']['new_members'] || params['list']['new_members'].empty?
      params['list']['new_members'].split.each do |screen_name|
        @list.add_member screen_name
      end
    end
    redirect '/'
  end


  post '/new_list' do
    @list = @user.new_list params['list']['name'], params['list']['private'] ? {:mode=>'private'} : {}
    params['list']['members'].split.each do |screen_name|
      @list.add_member screen_name
    end
    redirect '/'
  end
  
  delete '/:list_name' do
    @user.destroy_list params[:list_name]
    redirect '/'
  end
  
  get '/connect' do
    request_token = @client.authentication_request_token(:oauth_callback=>@@callback)
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
      redirect '/'
    else
      status 403
      'Not Authenticated'
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
  

end
