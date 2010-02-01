require 'spec_helper'
describe TwitterListManager do
  before do 
    TwitterOAuth::Client.stub!(:new).and_return(@client=mock('client',
      :rate_limit_status=>{"remaining_hits"=>150,"hourly_limit"=>150,"reset_time_in_seconds"=>0,"reset_time"=>"Sat Jan 01 00:00:00 UTC 2000"}
    ))
    TwitterOAuth::User.stub!(:new).and_return(@user = mock('user'))
    @authed_session = {'rack.session'=>{:user => {'screen_name'=>'tester'}}}
  end
  
  describe 'GET /' do
    
    it 'redirects to /login when unauthenticated' do
      get '/'
      last_response.should be_redirect
      last_response.location.should == '/login'
    end
    
    it 'lets you through if you are authed' do
      @user.stub!(:lists).and_return [mock('list',:null_object=>true)]
      get '/',{},@authed_session
      last_response.location.should be_nil
      last_response.should be_ok
    end
    
  end
  
  describe 'GET /login' do
    it 'is never redirected' do
      get '/login'
      last_response.location.should be_nil
      last_response.should be_ok
    end
  end
  
  describe 'PUT /:list_name' do
  
    before do
      @list = mock('list',:slug=>'test',:remove_member=>true)
      @user.stub!(:list).and_return @list
    end
  
    it 'gets the list from the user\'s lists' do
      @user.should_receive(:list).with('test').and_return @list
      put '/test', {'list'=>{'new_members'=>''}}, @authed_session
    end
  
    it 'removes checked members from the list' do
      @list.should_receive(:remove_member).with 'tester'
      put '/test', {'list'=>{'remove_members'=>{'tester'=>'on'}}}, @authed_session
    end
    
    it 'adds users listed in the text area' do
      @list.should_receive(:add_member).with 'tester'
      @list.should_receive(:add_member).with 'toaster'
      put '/test', {'list'=>{'new_members'=>'tester toaster'}}, @authed_session
    end
    
    describe 'missing list' do
      it 'should be 404 if the list does not exist' do
        @user.stub!(:list).and_return nil
        put '/test', {'list'=>{'remove_members'=>{'tester'=>'on'}}}, @authed_session
        last_response.status.should == 404
      end
    end
  end
  
  describe 'POST /new_list' do
    it 'creates a new list' do
      @user.should_receive(:new_list).with('test',{})
      post '/new_list',{'list'=>{'name'=>'test','members'=>''}},@authed_session
    end
    
    it 'adds members if there are some' do
      @list = mock('list',:slug=>'test',:remove_member=>true)
      @user.should_receive(:new_list).with('test',{}).and_return @list
      @list.should_receive(:add_member).with 'tester'
      post '/new_list',{'list'=>{'name'=>'test','members'=>'tester '}},@authed_session
      
    end
    it 'redirects back to \'/\'' do
      @user.stub!(:new_list)
      post '/new_list',{'list'=>{'name'=>'test','members'=>''}},@authed_session
      last_response.location.should == '/'
    end
  end
  
  describe 'DELETE /:list_name' do
    it 'destroys the list' do
      @user.should_receive(:destroy_list).with('test')
      delete '/test',{},@authed_session
    end
    
    it 'redirects back to \'/\'' do
      @user.stub!(:destroy_list)
      delete '/test',{},@authed_session
      last_response.location.should == '/'
    end
    
  end
  
  describe 'GET /connect' do
    it 'gets a request token' do
      @client.should_receive(:authentication_request_token).and_return(mock('request token',:authorize_url=>'http://example.com',:token=>'token',:secret=>'secret'))
      get '/connect'
    end
    it "redirects to the request token's auth url" do
      @client.stub!(:authentication_request_token).and_return(token = mock('request token',:token=>'token',:secret=>'secret'))
      token.should_receive(:authorize_url).and_return 'http://example.com'
      get '/connect'
      last_response.location.should == 'http://example.com'
    end
  end
  
  describe 'GET /auth' do
    describe "on auth denied" do
      it "responds with 'Not Authenticated' and a 403" do
        @client.stub!(:authorize).and_raise OAuth::Unauthorized.new
        @client.stub!(:authorized?).and_return false
        get '/auth'
        last_response.status.should == 403
        last_response.body.should == 'Not Authenticated'
      end
    end
    describe 'on auth success' do
      it "redirects to '/'" do
        @client.stub!(:authorize).and_return(mock('access token',:null_object => true))
        @client.stub!(:authorized?).and_return true
        @client.stub!(:info)
        get '/auth'
        last_response.location.should == '/'
      end
    end
  end
end
