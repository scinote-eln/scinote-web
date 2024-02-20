class WopiController < ActionController::Base
  include WopiUtil

  skip_before_action :verify_authenticity_token
  before_action :load_vars, :authenticate_user_from_token!
  before_action :verify_proof!

  # Only used for checkfileinfo
  def file_get_endpoint
    check_file_info
  end

  def file_contents_get_endpoint
    # get_file
    response.headers['X-WOPI-ItemVersion'] = @asset.version
    response.body = @asset.file.download
    send_data response.body, disposition: 'inline', content_type: 'text/plain'
  end

  def post_file_endpoint
    override = request.headers['X-WOPI-Override']
    case override
    when 'GET_LOCK'
      get_lock
    when 'PUT_RELATIVE'
      put_relative
    when 'LOCK'
      old_lock = request.headers['X-WOPI-OldLock']
      if old_lock.nil?
        lock
      else
        unlock_and_relock
      end
    when 'UNLOCK'
      unlock
    when 'REFRESH_LOCK'
      refresh_lock
    when 'GET_SHARE_URL'
      render body: nil, status: :not_implemented
    else
      render body: nil, status: :not_found
    end
  end

  # Only used for putfile
  def file_contents_post_endpoint
    logger.warn 'WOPI: post_file_contents called'
    put_file
  end

  private

  def check_file_info
    asset_owner_id = @asset.id.to_s
    asset_owner_id = @asset.created_by_id.to_s if @asset.created_by_id

    msg = {
      BaseFileName: @asset.file_name,
      OwnerId: asset_owner_id,
      Size: @asset.file_size,
      UserId: @user.id.to_s,
      Version: @asset.version.to_s,
      SupportsExtendedLockLength: true,
      SupportsGetLock: true,
      SupportsLocks: true,
      SupportsUpdate: true,
      # Setting all users to business until we figure out
      # which should NOT be business
      LicenseCheckForEditIsEnabled: true,
      UserFriendlyName: @user.name,
      UserCanWrite: @can_write,
      UserCanNotWriteRelative: true,
      CloseUrl: @close_url,
      DownloadUrl: url_for(controller: 'assets', action: 'download', id: @asset.id, host: ENV['WOPI_USER_HOST']),
      HostEditUrl: url_for(controller: 'assets', action: 'edit', id: @asset.id, host: ENV['WOPI_USER_HOST']),
      HostViewUrl: url_for(controller: 'assets', action: 'view', id: @asset.id, host: ENV['WOPI_USER_HOST']),
      BreadcrumbBrandName: @breadcrumb_brand_name,
      BreadcrumbBrandUrl: @breadcrumb_brand_url,
      BreadcrumbFolderName: @breadcrumb_folder_name,
      BreadcrumbFolderUrl: @breadcrumb_folder_url
    }
    response.headers['X-WOPI-HostEndpoint'] = ENV['WOPI_ENDPOINT_URL']
    response.headers['X-WOPI-MachineName'] = ENV['WOPI_ENDPOINT_URL']
    response.headers['X-WOPI-ServerVersion'] = Scinote::Application::VERSION

    render json: msg
  end

  def put_relative
    render body: nil, status: :not_implemented
  end

  def lock
    lock = request.headers['X-WOPI-Lock']
    logger.warn 'WOPI: lock; ' + lock.to_s
    return render body: nil, status: :not_found if lock.blank?

    @asset.with_lock do
      if @asset.locked?
        if @asset.lock == lock
          @asset.refresh_lock
          response.headers['X-WOPI-ItemVersion'] = @asset.version
          render body: nil, status: :ok
        else
          response.headers['X-WOPI-Lock'] = @asset.lock
          render body: nil, status: :conflict
        end
      else
        @asset.lock_asset(lock)
        response.headers['X-WOPI-ItemVersion'] = @asset.version
        render body: nil, status: :ok
      end
    end
  end

  def unlock_and_relock
    logger.warn 'lock and relock'
    lock = request.headers['X-WOPI-Lock']
    old_lock = request.headers['X-WOPI-OldLock']

    return render body: nil, status: :bad_request if lock.blank? || old_lock.blank?

    @asset.with_lock do
      if @asset.locked?
        if @asset.lock == old_lock
          @asset.unlock
          @asset.lock_asset(lock)
          response.headers['X-WOPI-ItemVersion'] = @asset.version
          render body: nil, status: :ok
        else
          response.headers['X-WOPI-Lock'] = @asset.lock
          render body: nil, status: :conflict
        end
      else
        response.headers['X-WOPI-Lock'] = ' '
        render body: nil, status: :conflict
      end
    end
  end

  def unlock
    lock = request.headers['X-WOPI-Lock']
    return render body: nil, status: :bad_request if lock.blank?

    @asset.with_lock do
      if @asset.locked?
        logger.warn "WOPI: current asset lock: #{@asset.lock}, unlocking lock #{lock}"
        if @asset.lock == lock
          @asset.unlock
          @asset.post_process_file # Space is already taken in put_file
          create_wopi_file_activity(@user, false)

          response.headers['X-WOPI-ItemVersion'] = @asset.version
          render body: nil, status: :ok
        else
          response.headers['X-WOPI-Lock'] = @asset.lock
          render body: nil, status: :conflict
        end
      else
        logger.warn 'WOPI: tried to unlock non-locked file'
        response.headers['X-WOPI-Lock'] = ' '
        render body: nil, status: :conflict
      end
    end
  end

  def refresh_lock
    lock = request.headers['X-WOPI-Lock']
    return render body: nil, status: :bad_request if lock.nil? || lock.blank?

    @asset.with_lock do
      if @asset.locked?
        if @asset.lock == lock
          @asset.refresh_lock
          response.headers['X-WOPI-ItemVersion'] = @asset.version
          response.headers['X-WOPI-ItemVersion'] = @asset.version
          render body: nil, status: :ok
        else
          response.headers['X-WOPI-Lock'] = @asset.lock
          render body: nil, status: :conflict
        end
      else
        response.headers['X-WOPI-Lock'] = ' '
        render body: nil, status: :conflict
      end
    end
  end

  def get_lock
    @asset.with_lock do
      response.headers['X-WOPI-Lock'] = @asset.locked? ? @asset.lock : ' '
      render body: nil, status: :ok
    end
  end

  def put_file
    @asset.with_lock do
      lock = request.headers['X-WOPI-Lock']
      if @asset.locked?
        if @asset.lock == lock
          logger.warn 'WOPI: replacing file'

          @team.release_space(@asset.estimated_size)
          @asset.last_modified_by = @user
          @asset.update_contents(request.body)
          @asset.save

          @team.take_space(@asset.estimated_size)
          @team.save

          @protocol&.update(updated_at: Time.now.utc)

          response.headers['X-WOPI-ItemVersion'] = @asset.version
          render body: nil, status: :ok
        else
          logger.warn 'WOPI: wrong lock used to try and modify file'
          response.headers['X-WOPI-Lock'] = @asset.lock
          render body: nil, status: :conflict
        end
      elsif !@asset.file_size.nil? && @asset.file_size.zero?
        logger.warn 'WOPI: initializing empty file'

        @team.release_space(@asset.estimated_size)
        @asset.update_contents(request.body)
        @asset.last_modified_by = @user
        @asset.save
        @team.save

        response.headers['X-WOPI-ItemVersion'] = @asset.version
        render body: nil, status: :ok
      else
        logger.warn 'WOPI: trying to modify unlocked file'
        response.headers['X-WOPI-Lock'] = ' '
        render body: nil, status: :conflict
      end
    end
  end

  def load_vars
    @asset = Asset.find_by(id: params[:id])
    if @asset.nil?
      render body: nil, status: :not_found
    else
      logger.warn "Found asset: #{@asset.id}"
      step_assoc = @asset.step
      result_assoc = @asset.result
      repository_cell_assoc = @asset.repository_cell
      @assoc = step_assoc unless step_assoc.nil?
      @assoc = result_assoc unless result_assoc.nil?
      @assoc = repository_cell_assoc unless repository_cell_assoc.nil?

      if @assoc.instance_of?(Step)
        @protocol = @asset.step.protocol
        @team = @protocol.team
      elsif @assoc.instance_of?(Result)
        @my_module = @assoc.my_module
        @team = @my_module.experiment.project.team
      elsif @assoc.instance_of?(RepositoryCell)
        @repository = @assoc.repository_column.repository
        @team = @repository.team
      end
    end
  end

  def authenticate_user_from_token!
    wopi_token = params[:access_token]
    if wopi_token.nil?
      logger.warn 'WOPI: nil wopi token'
      return render body: nil, status: :unauthorized
    end

    @user = User.find_by_valid_wopi_token(wopi_token)
    if @user.nil?
      logger.warn 'WOPI: no user with this token found'
      return render body: nil, status: :unauthorized
    end
    logger.warn "WOPI: user found by token #{wopi_token} ID: #{@user.id}"

    # This is what we get for settings permission methods with
    # current_user
    @user.permission_team = @team
    @current_user = @user
    if @assoc.instance_of?(Step)
      if @protocol.in_module?
        @can_read = can_read_protocol_in_module?(@protocol)
        @can_write = can_manage_step?(@assoc)
        @close_url = protocols_my_module_url(@protocol.my_module, only_path: false, host: ENV['WOPI_USER_HOST'])

        project = @protocol.my_module.experiment.project
        @breadcrumb_brand_name = project.name
        @breadcrumb_brand_url = project_url(project, only_path: false, host: ENV['WOPI_USER_HOST'])
        @breadcrumb_folder_name = @protocol.my_module.name
      else
        @can_read = can_read_protocol_in_repository?(@protocol)
        @can_write = can_manage_step?(@assoc)
        @close_url = protocols_url(only_path: false, host: ENV['WOPI_USER_HOST'])

        @breadcrump_brand_name = 'Projects'
        @breadcrumb_brand_url = root_url(only_path: false, host: ENV['WOPI_USER_HOST'])
        @breadcrumb_folder_name = 'Protocol managament'
      end
      @breadcrumb_folder_url = @close_url
    elsif @assoc.instance_of?(Result)
      @can_read = can_read_experiment?(@my_module.experiment)
      @can_write = can_manage_my_module?(@my_module)

      @close_url = my_module_results_url(@my_module, only_path: false, host: ENV['WOPI_USER_HOST'])

      @breadcrumb_brand_name  = @my_module.experiment.project.name
      @breadcrumb_brand_url   = project_url(@my_module.experiment.project,
                                            only_path: false,
                                            host: ENV['WOPI_USER_HOST'])
      @breadcrumb_folder_name = @my_module.name
      @breadcrumb_folder_url  = @close_url
    elsif @assoc.instance_of?(RepositoryCell)
      @can_read = can_read_repository?(@repository)
      @can_write = !@repository.is_a?(RepositorySnapshot) && can_edit_wopi_file_in_repository_rows?

      @close_url = repository_url(@repository, only_path: false, host: ENV['WOPI_USER_HOST'])

      @breadcrumb_brand_name  = @team.name
      @breadcrumb_brand_url   = @close_url
      @breadcrumb_folder_name = @assoc.repository_row.name
      @breadcrumb_folder_url  = @close_url
    end

    return render body: nil, status: :not_found unless @can_read
  end

  def verify_proof!
    token = params[:access_token].encode('utf-8')
    timestamp = request.headers['X-WOPI-TimeStamp'].to_i
    signed_proof = request.headers['X-WOPI-Proof']
    signed_proof_old = request.headers['X-WOPI-ProofOld']
    url = request.original_url.upcase.encode('utf-8')

    if convert_to_unix_timestamp(timestamp) + 20.minutes >= Time.now
      if wopi_verify_proof(token, timestamp, signed_proof, signed_proof_old, url)
        logger.warn 'WOPI: proof verification: successful'
      else
        logger.warn 'WOPI: proof verification: not verified'
        render body: nil, status: :internal_server_error
      end
    else
      logger.warn 'WOPI: proof verification: timestamp too old; ' +
                  timestamp.to_s
      render body: nil, status: :internal_server_error
    end
  rescue StandardError => e
    logger.warn 'WOPI: proof verification: failed; ' + e.message
    render body: nil, status: :internal_server_error
  end

  def can_edit_wopi_file_in_repository_rows?
    can_manage_repository_rows?(@repository)
  end
end
