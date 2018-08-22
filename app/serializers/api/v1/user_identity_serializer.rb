module Api
  module V1
    class UserIdentitySerializer < ActiveModel::Serializer
      attributes :provider, :uid
    end
  end
end
