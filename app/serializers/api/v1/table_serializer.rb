# frozen_string_literal: true

module Api
  module V1
    class TableSerializer < ActiveModel::Serializer
      type :tables
      attributes :id, :name, :contents

<<<<<<< HEAD
      include TimestampableModel

=======
>>>>>>> Pulled latest release
      def contents
        object.contents&.force_encoding(Encoding::UTF_8)
      end
    end
  end
end
