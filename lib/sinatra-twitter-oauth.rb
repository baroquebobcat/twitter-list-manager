require 'sinatra/base'

module Sinatra
  module TwitterOAuth
    def self.registered app
      app.helpers Helpers
      app.enable :sessions
      app.set :twitter_oauth_config, 
        :key      => 'changeme',
        :secret   => 'changeme',
        :callback => 'changeme',
        :login_template => {:text=>'<a href="/connect">Login using Twitter</a>'}
        
      app.get '/login' do
        redirect '/' if @user
        login_config = options.twitter_oauth_config[:login_template]
        engine = login_config.keys.first
        case engine
        when :text
          login_config[:text]
        else
          render engine, login_config[engine]
        end
      end
      
      app.get '/connect' do
        redirect_to_twitter_auth_url
      end

      app.get '/auth' do
        if authenticate!
          redirect '/'
        else
          status 403
          'Not Authenticated'
        end
      end
      
      app.get '/logout' do
        clear_oauth_session
        redirect '/login'
      end
    end
    
    module Helpers
      
      #options
      # key -- oauth consumer key
      # secret -- oauth consumer secret
      # callback -- oauth callback url. Must be absolute. e.g. http://example.com/auth
      # login_template -- a single entry hash with the engine as the key e.g. :login_template => {:haml => :login}
      def twitter_oauth_config options
        options.twitter_oauth_config.merge! options
      end
      
      def login_required
        setup_client
        
        @user = ::TwitterOAuth::User.new(@client, session[:user]) if session[:user]
        
        @rate_limit_status = @client.rate_limit_status
        
        redirect '/login' unless @user
      end
      
      def setup_client
        @client ||= ::TwitterOAuth::Client.new(
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
  end
end
