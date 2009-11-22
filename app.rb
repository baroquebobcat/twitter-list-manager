require 'rubygems'
require 'sinatra/base'
require 'twitter_oauth'
require 'haml'

##http://github.com/banux/twitter_oauth/blob/159f46d45e93f8a211c7629c44afb8bba95910c5/lib/twitter_oauth/lists.rb
module TwitterOAuth
  class Client
 
    def lists(user)
      oauth_response = access_token.get("/#{user}/lists.json")
      JSON.parse(oauth_response.body)
    end
 
    def list_members(user, list, cursor="-1")
      oauth_response = access_token.get("/#{user}/#{list}/members.json?cursor=" + cursor)
      JSON.parse(oauth_response.body)
    end
 
    def subscribers(user)
      oauth_response = access_token.get("/#{user}/subscribers.json", options)
      JSON.parse(oauth_response.body)
    end
 
  end
end
 
##

#
# borrowed heavily from http://github.com/moomerman/sinitter
#
class TwitterListManager <Sinatra::Base

  configure do
    set :sessions, true
    set :views, File.dirname(__FILE__) + '/views'

    @@config = {
      :consumer_key=>ENV['TWITTER_OAUTH_KEY'],
      :consumer_secret=>ENV['TWITTER_OAUTH_SECRET']
    }
  end

  before do
    @user = session[:user]
    @client = TwitterOAuth::Client.new(
      @@config.merge(
        :token  => session[:access_token],
	:secret => session[:secret_token]
      )
    )
    @rate_limit_status = @client.rate_limit_status
  end

  get '/' do
    redirect '/connect' unless @user
    haml :home
  end

  get '/connect' do
    request_token = @client.request_token
    session[:request_token] = request_token.token
    session[:request_token_secret]=request_token.secret
    redirect request_token.authorize_url#.gsub('authorize','authenticate')
  end

  get '/auth' do
    @access_token = @client.authorize(
        session[:request_token],
        session[:request_token_secret]
    )
    if @client.authorized?
      session[:access_token] = @access_token.token
      session[:secret_token] = @access_token.secret
      session[:user]=@client.info
      redirect '/'
    else
      pass
    end
  end
end
