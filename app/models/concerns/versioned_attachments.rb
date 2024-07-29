# frozen_string_literal: true

module VersionedAttachments
  extend ActiveSupport::Concern

  class_methods do
    def has_one_versioned_attached(name)
      has_one_attached name, dependent: :detach
      has_many_attached "previous_#{name.to_s.pluralize}", dependent: :detach

      define_method "attach_#{name}_version" do |*args, **options|
        ActiveRecord::Base.transaction(requires_new: true) do
          __send__("previous_#{name.to_s.pluralize}").attach(__send__(name).blob) if __send__(name).attached?
          __send__(name).attach(*args, **options)
        end
      end
    end
  end
end
