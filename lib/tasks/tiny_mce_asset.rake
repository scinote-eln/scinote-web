namespace :tiny_mce_asset do
  REGEX = /\[~tiny_mce_id:([0-9a-zA-Z]+)\]/
  desc 'Remove obsolete images that were created on new steps or '\
       'results and the step/result didn\'t get saved.'
  task remove_obsolete_images: :environment do
    TinyMceAsset.where('step_id IS ? AND ' \
                       'result_text_id IS ? AND created_at < ?',
                       nil, nil, 7.days.ago).destroy_all
  end

  desc 'Generate new tiny_mce_assets and replace old assets in RTE for ' \
       'steps. Assign the last printed id if the script crashes or ' \
       'id + 1 if there is a problematic asset'
  task :regenerate_step_images, [:last_id] => :environment do |_, args|
    replaced_images = 0
    failed_attempts = 0
    all_images = TinyMceAsset.where.not(step: nil).count
    failed_attempts_ids = []
    puts 'Start processing steps...'
    params = { batch_size: 100 }
    if args.present? && args[:last_id].present?
      # fetch all steps and sort them asc
      params[:start] = args[:last_id].to_i
    end
    Step.find_each(params) do |step|
      next unless step.description && step.description.match(REGEX)
      team = step.protocol.team
      puts "******************************* \n\n\n\n"
      puts "Processing step id => [#{step.id}] \n\n\n\n"
      puts '*******************************'
      step.description.gsub!(REGEX) do |el|
        match = el.match(REGEX)
        old_img = TinyMceAsset.find_by_id(match[1])
        # skip other processing and deletes tiny_mce tag
        # if image is not in database
        next unless old_img
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

    puts '----------- TASK REPORT -----------------'
    puts "All images: #{all_images}"
    puts "Recreated images: #{replaced_images}"
    puts "Failed attempts: #{failed_attempts}"
    puts "TinyMceAsset ids of failed attempts: #{failed_attempts_ids}"
    puts '-----------------------------------------'
  end

  desc 'Generate new tiny_mce_assets and replace old assets in RTE ' \
       'for results. Assign the last printed id if the script crashes or ' \
       'id + 1 if there is a problematic asset'
  task :regenerate_results_images, [:last_id] => :environment do |_, args|
    replaced_images = 0
    failed_attempts = 0
    all_images = TinyMceAsset.where.not(result_text: nil).count
    failed_attempts_ids = []
    params = { batch_size: 100 }
    if args.present? && args[:last_id].present?
      params[:start] = args[:last_id].to_i
    end

    puts 'Start processing result_texts...'
    ResultText.find_each(params) do |result_text|
      next unless result_text.text && result_text.text.match(REGEX)
      team = result_text.result.my_module.protocol.team
      puts "******************************************* \n\n\n\n"
      puts "Processing result_text id => [#{result_text.id}] \n\n\n\n"
      puts '*******************************************'
      result_text.text.gsub!(REGEX) do |el|
        match = el.match(REGEX)
        old_img = TinyMceAsset.find_by_id(match[1])
        # skip other processing and deletes tiny_mce tag
        # if image is not in database
        next unless old_img
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
