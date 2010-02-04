require 'rubygems'
require 'sinatra/base'
require 'haml'

require 'lib/twitter_oauth_ext'
require 'lib/sinatra-twitter-oauth'

#
# Started with http://github.com/moomerman/sinitter,
# moomerman's example of how to use twitter_oauth,
# and modified it.
#
# 
class TwitterListManager < Sinatra::Base
  register Sinatra::TwitterOAuth
  
  configure do
  
    enable :methodoverride
    
    enable :logging

    set :views, File.dirname(__FILE__) + '/views'

    self.twitter_oauth_config= {
      :key      =>ENV['TWITTER_OAUTH_KEY'],
      :secret   =>ENV['TWITTER_OAUTH_SECRET'],
      :callback => ENV['TWITTER_OAUTH_CALLBACK'],
      :login_template => {:haml => :login}
    }
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

end
