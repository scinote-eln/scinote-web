class Users::RegistrationsController < Devise::RegistrationsController
  prepend_before_action :check_captcha, only: [:create]

  def avatar
    user = User.find_by_id(params[:id]) || current_user
    style = params[:style] || "icon_small"
    # TODO: Maybe avatar should be an Asset, so it's methods could be used,
    # e.g. presigned_url in this case
    redirect_to user.avatar.url(style.to_sym), status: 307
  end

  # Validates asset and then generates S3 upload posts, because
  # otherwise untracked files could be uploaded to S3
  def signature
    respond_to do |format|
      format.json {

        # Changed avatar values are only used for pre-generating S3 key
        # and user object is not persisted with this values.
        current_user.empty_avatar avatar_params[:file].original_filename,
                                  avatar_params[:file].size

        validation_asset = Asset.new(avatar_params)
        if current_user.valid? && validation_asset.valid?
          render json: {
            posts: generate_upload_posts
          }
        else
          if validation_asset.errors[:file].any?
            # Add file content error
            current_user.errors[:avatar] << validation_asset.errors[:file].first
          end
          render json: {
            status: 'error',
            errors: current_user.errors
          }, status: :bad_request
        end
      }
    end
  end

  def update_resource(resource, params)
    @user_avatar_url = avatar_path(current_user, :thumb)

    if params.include? :change_password
      # Special handling if changing password
      params.delete(:change_password)
      if (
        resource.valid_password?(params[:current_password]) and
        params.include? :password and
        params.include? :password_confirmation and
        params[:password].blank?
      ) then
        # If new password is blank and we're in process of changing
        # password, add error to the resource and return false
        resource.errors.add(:password, :blank)
        false
      else
        resource.update_with_password(params)
      end
    elsif params.include? :change_avatar
      params.delete(:change_avatar)
      unless params.include? :avatar
        resource.errors.add(:avatar, :blank)
        false
      else
        resource.update_without_password(params)
      end
    elsif params.include? :email or params.include? :password
      # For changing email or password, validate current_password
      resource.update_with_password(params)

    else
      # For changing some attributes, no current_password validation
      # is required
      resource.update_without_password(params)
    end
  end

  # Override default registrations_controller.rb implementation
  # to support JSON
  def update
    change_password = account_update_params.include? :change_password
    respond_to do |format|
      self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
      prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

      resource_updated = update_resource(resource, account_update_params)

      yield resource if block_given?
      if resource_updated
        # Set "needs confirmation" flash if neccesary
        if is_flashing_format?
          flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ?
            :update_needs_confirmation : :updated
          set_flash_message :notice, flash_key
        end

        # Set "password successfully updated" flash if neccesary
        if change_password
          set_flash_message :notice, :password_changed
        end

        format.html {
          sign_in resource_name, resource, bypass: true
          respond_with resource, location: edit_user_registration_path
        }
        format.json {
          flash.keep
          sign_in resource_name, resource, bypass: true
          render json: {}
        }
      else
        clean_up_passwords resource
        format.html {
          respond_with resource, location: edit_user_registration_path
        }
        format.json {
          render json: resource.errors, status: :bad_request
        }
      end
    end
  end

  def create
    build_resource(sign_up_params)
    valid_resource = resource.valid?

    # Create new organization for the new user
    @org = Organization.new
    @org.name = params[:organization][:name]
    valid_org = @org.valid?

    if valid_org && valid_resource

      # this must be called after @org variable is defined. Otherwise this
      # variable won't be accessable in view.
      super do |resource|
        # Set the confirmed_at == created_at IF not using email confirmations
        unless Rails.configuration.x.enable_email_confirmations
          resource.update(confirmed_at: resource.created_at)
        end

        if resource.valid? && resource.persisted?
          @org.created_by = resource # set created_by for oraganization
          @org.save

          # Add this user to the organization as owner
          UserOrganization.create(
            user: resource,
            organization: @org,
            role: :admin
          )

          # set current organization to new user
          resource.current_organization_id = @org.id
          resource.save
        end
      end
    else
      render :new
    end
  end

  protected

  # Called upon creating User (before .save). Permits parameters and extracts
  # initials from :full_name (takes at most 4 chars). If :full_name is empty, it
  # uses "PLCH" as a placeholder (user won't get error complaining about
  # initials being empty.
  def sign_up_params
    tmp = params.require(:user).permit(:full_name, :initials, :email, :password, :password_confirmation)
    initials = tmp[:full_name].titleize.scan(/[A-Z]+/).join()
    initials = if initials.strip.empty?
                 'PLCH'
               else
                 initials[0..Constants::USER_INITIALS_MAX_LENGTH]
               end
    tmp.merge(:initials => initials)
  end

  def account_update_params
    params.require(:user).permit(
      :full_name,
      :initials,
      :avatar,
      :avatar_file_name,
      :email,
      :password,
      :password_confirmation,
      :current_password,
      :change_password,
      :change_avatar
    )
  end

  def avatar_params
    params.permit(
      :file
    )
  end

  # Generates posts for uploading files (many sizes of same file)
  # to S3 server
  def generate_upload_posts
    posts = []
    file_size = current_user.avatar_file_size
    content_type = current_user.avatar_content_type
    s3_post = S3_BUCKET.presigned_post(
      key: current_user.avatar.path[1..-1],
      success_action_status: '201',
      acl: 'private',
      storage_class: "STANDARD",
      content_length_range: file_size..file_size,
      content_type: content_type
    )
    posts.push({
      url: s3_post.url,
      fields: s3_post.fields
    })

    current_user.avatar.options[:styles].each do |style, option|
      s3_post = S3_BUCKET.presigned_post(
        key: current_user.avatar.path(style)[1..-1],
        success_action_status: '201',
        acl: 'public-read',
        storage_class: "REDUCED_REDUNDANCY",
        content_length_range: 1..Constants::FILE_MAX_SIZE_MB.megabytes,
        content_type: content_type
      )
      posts.push({
        url: s3_post.url,
        fields: s3_post.fields,
        style_option: option,
        mime_type: content_type
      })
    end

    posts
  end

  private

  def check_captcha
    if Rails.configuration.x.enable_recaptcha
      unless verify_recaptcha
        # Construct new resource before rendering :new
        self.resource = resource_class.new sign_up_params

        # Also validate organization
        @org = Organization.new(name: params[:organization][:name])
        @org.valid?

        respond_with_navigational(resource) { render :new }
      end
    end
  end

  # Redirect to login page after signing up
  def after_sign_up_path_for(resource)
    new_user_session_path
  end

  # Redirect to login page after signing up
  def after_inactive_sign_up_path_for(resource)
    new_user_session_path
  end
end
