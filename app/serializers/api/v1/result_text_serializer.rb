# frozen_string_literal: true

module Api
  module V1
    class ResultTextSerializer < ActiveModel::Serializer
      type :result_texts
      attributes :name, :text, :archived

      def archived
        object.archived? if object.result_orderable_element.present?
      end
    end
  end
end
