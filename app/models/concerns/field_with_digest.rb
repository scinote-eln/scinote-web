# frozen_string_literal: true

module FieldWithDigest
  extend ActiveSupport::Concern

  class_methods do
    def field_with_digest(name)
      define_method :"#{name}_digest" do
        # Hash the value stored in the DB: rendering (e.g. tinymce_render) can rewrite the in-memory value
        Digest::SHA256.hexdigest(attribute_in_database(name).to_s)
      end
    end
  end
end
