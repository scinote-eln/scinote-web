module ApiHelper
  def generate_token(user_id)
    Api::CoreJwt.encode(sub: user_id)
  end

  def generate_expired_token(user_id)
    Api::CoreJwt.encode({ sub: user_id }, (Time.now.to_i - 300))
  end

  def decode_token(token)
    Api::CoreJwt.decode(token)['sub'].to_i
  end

  def json
    ActiveSupport::HashWithIndifferentAccess.new(JSON.parse(response.body))
  end
end
