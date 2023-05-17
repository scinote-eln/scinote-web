# frozen_string_literal: true

module Api
  module V1
    class ProtocolTemplateSerializer < ProtocolSerializer
      type :protocol_templates
      attributes :version_number, :version_comment, :published_on, :archived
      belongs_to :published_by, serializer: UserSerializer
    end
  end
end
