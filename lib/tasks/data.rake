namespace :data do
  Rails.logger = Logger.new(STDOUT)

  def confirm(message)
    puts "\n#{message}? (Y/n)"
    res = $stdin.gets.to_s.downcase
    unless res.in?(["y", "n", "\n"]) then
      puts "Invalid answer, enter option Y or n."
      confirm(message)
    end
    res.in?(["y", "\n"])
  end

  desc "Remove expired temporary files"
  task clean_temp_files: :environment do
    if not confirm "Remove expired temporary files"
      next
    end
    Rails.logger.info "Cleaning temporary files older than 3 days"
    TempFile.where("created_at < ?", 3.days.ago).each do |tmp_file|

      TempFile.transaction do
        begin
          tmp_file.destroy!
        rescue Exception => e
          Rails.logger.error "Failed to destroy temporary file #{tmp_file.id}: #{e}"
          raise ActiveRecord::Rollback
        else
          Rails.logger.info "Temporary file ##{tmp_file.id} removed"
        end
      end
    end
  end

  desc "Remove unconfirmed user accounts"
  task clean_unconfirmed_users: :environment do
    if not confirm "Remove unconfirmed user accounts"
      next
    end
    Rails.logger.info "Cleaning unconfirmed users older than 3 days"
    User.where("confirmed_at = ? and created_at < ?", nil, 3.days.ago).each do |user|

      User.transaction do
        begin
          user.destroy!
        rescue Exception => e
          Rails.logger.error "Failed to destroy unconfirmed user #{user.id}: #{e}"
          raise ActiveRecord::Rollback
        else
          Rails.logger.info "Unconfirmed user ##{user.id} removed"
        end
      end
    end
  end

  desc "Remove temporary and obsolete data"
  task clean: [:environment, :clean_temp_files, :clean_unconfirmed_users]

end
