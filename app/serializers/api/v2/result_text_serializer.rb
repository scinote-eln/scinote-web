# frozen_string_literal: true

module Api
  module V2
    class ResultTextSerializer < ActiveModel::Serializer
      type :result_texts
      attributes :name, :text

      def text
        object.tinymce_render('text')
      end
    end
  end
end
