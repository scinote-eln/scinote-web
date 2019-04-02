# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
namespace :tinymce_assets do
  desc 'Migrate old TinyMCE images to new polymorphic format' \
       'IT SHOULD BE RUN ONE TIME ONLY'
  task migrate_tinymce_assets: :environment do
    old_images = TinyMceAsset.where('step_id IS NOT NULL OR result_text_id IS NOT NULL')
    old_images.each do |old_image|
      old_format = /\[~tiny_mce_id:#{old_image.id}\]/
      new_format = "<img src='' class='img-responsive' data-mce-token='#{Base62.encode(old_image.id)}'/>"
      if old_image.step_id
        object = old_image.step
        object.description.sub!(old_format, new_format)
      else
        object = old_image.result_text
        object.text.sub!(old_format, new_format)
      end
      object.save
      old_image.update(object: object, step_id: nil, result_text_id: nil)
    end
  end
end
# rubocop:enable Metrics/LineLength
