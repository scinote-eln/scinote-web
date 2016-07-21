namespace :data do
  Rails.logger = Logger.new(STDOUT)

  desc "Remove expired temporary files"
  task clean_temp_files: :environment do
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

  def destroy_users(users)
    users.each do |user|

      User.transaction do
        begin
          # Destroy user_organization, and possibly organization
          if user.organizations.count > 0
            oids = user.organizations.pluck(:id)
            oids.each do |oid|
              org = Organization.find(oid)
              user_org = user.user_organizations.where(organization: org).first
              destroy_org = (org.users.count == 1 && org.created_by == user)
              if !user_org.destroy(nil) then
                raise Exception
              end
              org.destroy! if destroy_org
            end
          end

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

  desc "Remove unconfirmed user accounts"
  task clean_unconfirmed_users: :environment do
    Rails.logger.info "Cleaning unconfirmed users"

    # First, remove the users who signed up by themselves
    users = User
    .where(confirmed_at: nil)
    .where.not(confirmation_token: nil)
    .where(invitation_token: nil)
    .where("created_at < ?", Devise.confirm_within.ago)
    destroy_users(users)

    # Now, remove users who were invited
    users = User
    .where(confirmed_at: nil)
    .where(invitation_accepted_at: nil)
    .where(confirmation_token: nil)
    .where.not(invitation_token: nil)
    .where("created_at < ?", Devise.invite_for.ago)
    destroy_users(users)
  end

  desc "Remove temporary and obsolete data"
  task clean: [:environment, :clean_temp_files, :clean_unconfirmed_users]

end
