module ControllerMacros
  def login_user
    before(:each) do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      user = create :user
      user.confirm
      sign_in user
    end
  end

  def login_api_user
    before(:each) do
      user = create :user
      user.confirm

      @request.headers.merge!({
        'Authorization': 'Bearer ' + Api::CoreJwt.encode(sub: user.id),
        'Content-Type': 'application/json'
      })

      subject.send(:authenticate_request!)
    end
  end
end
