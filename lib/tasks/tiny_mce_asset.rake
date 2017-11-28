namespace :tiny_mce_asset do
  desc 'Remove obsolete images that were created on new steps or '\
       'results and the step/result didn\'t get saved.'
  task remove_obsolete_images: :environment do
    TinyMceAsset.where('step_id IS ? AND ' \
                       'result_text_id IS ? AND created_at < ?',
                       nil, nil, 7.days.ago).destroy_all
  end

  desc 'Generate new tiny_mce_assets and replace old assets in RTE'
  task regenerate_images: :environment do
    regex = /\[~tiny_mce_id:([0-9a-zA-Z]+)\]/
    replaced_images = 0
    failed_attempts = 0
    all_images = TinyMceAsset.count
    failed_attempts_ids = []
    puts 'Start processing steps...'
    Step.find_each do |step|
      next unless step.description && step.description.match(regex)
      team = step.protocol.team
      step.description.gsub!(regex) do |el|
        match = el.match(regex)
        old_img = TinyMceAsset.find_by_id(match[1])
        new_img = TinyMceAsset.create(image: old_img.image,
                                      team: team,
                                      reference: step)
        if new_img
          # This image will be removed by `remove_obsolete_images` rake task
          # until all the steps are not updated we still need this image
          # in case it appears on some other step
          old_img.update_attributes(result_text_id: nil, step_id: nil)
          replaced_images += 1
          "[~tiny_mce_id:#{new_img.id}]"
        else
          failed_attempts += 1
          failed_attempts_ids << old_img.id
          "[~tiny_mce_id:#{old_img.id}]" # return the old img
        end
      end
      step.save
    end
    puts 'Completed processing steps...'
    puts 'Start processing result_texts...'
    ResultText.find_each do |result_text|
      next unless result_text.text && result_text.text.match(regex)
      team = result_text.result.my_module.protocol.team
      result_text.text.gsub!(regex) do |el|
        match = el.match(regex)
        old_img = TinyMceAsset.find_by_id(match[1])
        new_img = TinyMceAsset.create(image: old_img.image,
                                      team: team,
                                      reference: result_text)
        if new_img
          # This image will be removed by `remove_obsolete_images` rake task
          # until all the steps are not updated we still need this image
          # in case it appears on some other step
          old_img.update_attributes(result_text_id: nil, step_id: nil)
          replaced_images += 1
          "[~tiny_mce_id:#{new_img.id}]"
        else
          failed_attempts += 1
          failed_attempts_ids << old_img.id
          "[~tiny_mce_id:#{old_img.id}]" # return the old img
        end
      end
      result_text.save
    end
    puts 'Completed processing result_texts...'
    puts '----------- TASK REPORT -----------------'
    puts "All images: #{all_images}"
    puts "Recreated images: #{replaced_images}"
    puts "Failed attempts: #{failed_attempts}"
    puts "TinyMceAsset ids of failed attempts: #{failed_attempts_ids}"
    puts '-----------------------------------------'
  end
end
