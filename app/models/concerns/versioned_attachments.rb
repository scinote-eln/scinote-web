# frozen_string_literal: true

module VersionedAttachments
  extend ActiveSupport::Concern

  class_methods do
    def has_one_versioned_attached(name)
      has_one_attached name
      has_many_attached "previous_#{name.to_s.pluralize}"

      define_method :"attach_#{name}_version" do |*args, **options|
        ActiveRecord::Base.transaction(requires_new: true) do
          __send__(:"previous_#{name.to_s.pluralize}").attach([__send__(name).blob.signed_id]) if __send__(name).attached?
          __send__(name).attach(*args, **options)

          new_blob = __send__(name).blob
          new_blob.metadata['created_by_id'] ||= last_modified_by_id

          # set version of current latest file if previous versions exist
          new_blob.save! and next unless __send__(:"previous_#{name.to_s.pluralize}").any?

          new_version =
            (__send__(:"previous_#{name.to_s.pluralize}").last.blob.metadata['version'] || 1) + 1
          new_blob.metadata['version'] = new_version
          new_blob.save!
        end
      end

      define_method :"restore_#{name}_version" do |version|
        ActiveRecord::Base.transaction(requires_new: true) do
          blob = __send__(:"previous_#{name.to_s.pluralize}").map(&:blob).find do |b|
            (b.metadata['version'] || 1) == version
          end

          blob.open do |tmp_file|
            new_blob = ActiveStorage::Blob.create_and_upload!(
              io: tmp_file,
              filename: blob.filename,
              metadata: blob.metadata.merge({ 'restored_from_version' => version, 'created_by_id' => last_modified_by_id })
            )

            __send__(:"attach_#{name}_version", new_blob)
          end
        end
      end
    end
  end

  module_function

  def enabled?
    ApplicationSettings.instance.values['versioned_attachments_enabled']
  end

  def disabled_disclaimer
    {
      text: I18n.t('assets.file_versions_modal.disabled_disclaimer'),
      button: I18n.t('assets.file_versions_modal.enable_button')
    }
  end
end
