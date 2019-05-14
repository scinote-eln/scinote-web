# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
namespace :tinymce_assets do
  desc 'Migrate old TinyMCE images to new polymorphic format' \
       'IT SHOULD BE RUN ONE TIME ONLY'
  task migrate_tinymce_assets: :environment do
    ActiveRecord::Base.no_touching do
      old_images = TinyMceAsset.where('step_id IS NOT NULL OR result_text_id IS NOT NULL')
                               .where(object: nil)
                               .preload(:step, :result_text)
      old_images.find_each do |old_image|
        ActiveRecord::Base.transaction do
          old_format = /\[~tiny_mce_id:#{old_image.id}\]/
          new_format = "<img src='' class='img-responsive' data-mce-token='#{Base62.encode(old_image.id)}'/>"
          if old_image.step_id
            object = old_image.step
            object.description.sub!(old_format, new_format)
          else
            object = old_image.result_text
            object.text.sub!(old_format, new_format)
          end
          object.save!
          old_image.update!(object_id: object.id, object_type: object.class.to_s, step_id: nil, result_text_id: nil)
        rescue StandardError => ex
          Rails.logger.error "Failed to update TinyMceAsset id: #{old_image.id}"
          Rails.logger.error ex.message
          raise ActiveRecord::Rollback
        end
      end
    end
  end
end
# rubocop:enable Metrics/LineLength
