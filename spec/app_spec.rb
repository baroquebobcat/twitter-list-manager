require 'spec_helper'
describe TwitterListManager do
  before do 
    TwitterOAuth::Client.stub!(:new).and_return(@client=mock('client',
      :rate_limit_status=>100
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
  
  describe 'POST /update_list/:list' do
    before do
      @list = mock('list',:slug=>'test',:remove_member=>true)
      @user.stub!(:list).and_return @list
    end

    it 'removes checked members from the list' do
      @list.should_receive(:remove_member).with 'tester'
      post '/update_list/test', {'lists'=>{'test'=>{'remove_members'=>{'tester'=>'on'}}}}, @authed_session
    end
    
    it 'adds users listed in the text area' do
      @list.should_receive(:add_member).with 'tester'
      @list.should_receive(:add_member).with 'toaster'
      post '/update_list/test', {'lists'=>{'test'=>{'new_members'=>'tester toaster'}}}, @authed_session
    end
    
    describe 'missing list' do
      it 'should be 404 if the list does not exist' do
        @user.stub!(:list).and_return nil
        post '/update_list/test', {'lists'=>{'test'=>{'remove_members'=>{'tester'=>'on'}}}}, @authed_session
        last_response.status.should == 404
      end
    end
  end
end
