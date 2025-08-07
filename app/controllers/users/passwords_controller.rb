class Users::PasswordsController < Devise::PasswordsController
  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if resource.errors.added?(:email, :blank)
      flash.now[:alert] = I18n.t('devise.errors.email.empty')
      self.resource = resource_class.new
      render :new
    else
      set_flash_message!(:notice, :send_instructions)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?

    if resource.errors.blank?
      resource.unlock_access! if unlockable?(resource)
      if log_in_after_password_reset(resource)
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message!(:notice, flash_message)
        resource.after_database_authentication if check_database_authentication?(resource)
        sign_in(resource_name, resource, event: :authentication)
      else
        set_flash_message!(:notice, :updated_not_active)
      end
      respond_with resource, location: after_resetting_password_path_for(resource)
    else
      set_minimum_password_length
      respond_with resource
    end
  end

  protected

  def after_resetting_password_path_for(resource)
    log_in_after_password_reset(resource) ? after_sign_in_path_for(resource) : new_session_path(resource_name)
  end

  def log_in_after_password_reset(user)
    !user.two_factor_auth_enabled?
  end

  def check_database_authentication?(_)
    true
  end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
