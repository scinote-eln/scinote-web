# frozen_string_literal: true

module Api
  module V2
    class ResultTextSerializer < ActiveModel::Serializer
      type :result_texts
      attributes :name, :text, :archived

      def text
        object.tinymce_render('text')
      end

      def archived
        object.archived? if object.result_orderable_element.present?
      end
    end
  end
end
