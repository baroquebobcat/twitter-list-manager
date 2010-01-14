require 'rubygems'
require 'sinatra/base'
require 'twitter_oauth'
require 'haml'

require 'lib/twitter_oauth_ext'

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
    
    redirect '/login' unless @user
  end

  get '/login' do
    redirect '/' if @user
    '<a href=/connect>connect through twitter</a>'
  end

  get '/' do
    @lists = @user.lists
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
      redirect '/'
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
