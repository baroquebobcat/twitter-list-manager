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
end
