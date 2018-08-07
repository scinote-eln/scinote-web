module Api
  module V1
    class RepositoryTextValueSerializer < ActiveModel::Serializer
      attribute :formatted, key: :value
    end
  end
end
