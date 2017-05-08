namespace :tiny_mce_asset do
  desc 'Remove obsolete images that were created on new steps or '\
       'results and the step/result didn\'t get saved.'
  task remove_obsolete_images: :environment do
    TinyMceAsset.where('step_id IS ? AND ' \
                       'result_text_id IS ? AND created_at < ?',
                       nil, nil, 7.days.ago)
  end
end
