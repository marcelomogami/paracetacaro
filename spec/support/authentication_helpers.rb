module AuthenticationHelpers
  def login_as(user, password: "password123")
    post user_session_path, params: { user: { email: user.email, password: password } }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
