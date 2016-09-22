class WopiController < ActionController::Base
  include WopiUtil

  before_action :load_vars,:authenticate_user_from_token!
  before_action :verify_proof!

  def get_file_endpoint
    logger.warn "get_file called"
    #Only used for checkfileinfo
    check_file_info
  end

  def get_file_contents_endpoint
    logger.warn "get_file_contents called"
    #Only used for getfile
    get_file

  end

  def post_file_endpoint
    logger.warn "post_file called"
    override = request.headers["X-WOPI-Override"]
    case override
    when "GET_LOCK"
        get_lock
      when "PUT_RELATIVE"
        put_relative
      when "LOCK"
        old_lock = request.headers["X-WOPI-OldLock"]
        if old_lock.nil?
          lock
        else
          unlock_and_relock
        end
      when "UNLOCK"
        unlock
      when "REFRESH_LOCK"
        refresh_lock
      when "GET_SHARE_URL"
        render :nothing => true, :status => 501 and return
      else
        render :nothing => true, :status => 404 and return
      end
  end

  def post_file_contents_endpoint
    logger.warn "post_file_contents called"
    #Only used for putfile
    put_file
  end

  def check_file_info
      logger.warn "Check file info started"
      msg = { :BaseFileName => @asset.file_file_name,
            :OwnerId => @asset.created_by_id.to_s,
            :Size => @asset.file_file_size,
            :UserId => @user.id,
            :Version => @asset.version,
            :SupportsExtendedLockLength => true,
            :SupportsGetLock => true,
            :SupportsLocks => true,
            :SupportsUpdate => true,
            #Setting all users to business until we figure out which should NOT be business
            :LicenseCheckForEditIsEnabled => true,
            :UserFriendlyName => @user.name,
            #TODO Check user permisisons
            :ReadOnly => false,
            :UserCanNotWriteRelative => true,
            :UserCanWrite => true,
            #TODO decide what to put here
            :CloseUrl => "https://scinote-preview.herokuapp.com",
            :DownloadUrl => url_for(controller: 'assets',action: 'download',id: @asset.id),
            :HostEditUrl => url_for(controller: 'assets',action: 'edit',id: @asset.id),
            :HostViewUrl => url_for(controller: 'assets',action: 'view',id: @asset.id)
            #TODO breadcrumbs?
            #:FileExtension
          }
      response.headers['X-WOPI-HostEndpoint'] = ENV["WOPI_ENDPOINT_URL"]
      response.headers['X-WOPI-MachineName'] = ENV["WOPI_ENDPOINT_URL"]
      response.headers['X-WOPI-ServerVersion'] = APP_VERSION
      render json:msg and return

  end

  def get_file
    logger.warn "getting file"
    response.headers["X-WOPI-ItemVersion"] = @asset.version
    response.body = Paperclip.io_adapters.for(@asset.file).read
    send_data response.body, disposition: "inline", :content_type => 'text/plain'
  end

  def put_relative
    logger.warn "put relative"
    render :nothing => true, :status => 501 and return
  end

  def lock
    logger.warn "lock"
    lock = request.headers["X-WOPI-Lock"]
    if lock.nil? || lock.blank?
      render :nothing => true, :status => 400 and return
    end
    @asset.with_lock do
      if @asset.is_locked
        if @asset.lock == lock
          @asset.refresh_lock
          response.headers["X-WOPI-ItemVersion"] = @asset.version
          render :nothing => true, :status => 200 and return
        else
          response.headers["X-WOPI-Lock"] = @asset.lock
          render :nothing => true, :status => 409 and return
        end
      else
        @asset.lock_asset(lock)
        response.headers["X-WOPI-ItemVersion"] = @asset.version
        render :nothing => true, :status => 200 and return
      end
    end
  end

  def unlock_and_relock
    logger.warn "lock and relock"
    lock = request.headers["X-WOPI-Lock"]
    old_lock = request.headers["X-WOPI-OldLock"]
    if lock.nil? || lock.blank? || old_lock.blank?
      render :nothing => true, :status => 400 and return
    end
    @asset.with_lock do
      if @asset.is_locked
        if @asset.lock == old_lock
          @asset.unlock
          @asset.lock_asset(lock)
          response.headers["X-WOPI-ItemVersion"] = @asset.version
          render :nothing => true, :status => 200 and return
        else
          response.headers["X-WOPI-Lock"] = @asset.lock
          render :nothing => true, :status => 409 and return
        end
      else
        response.headers["X-WOPI-Lock"] = ""
        render :nothing => true, :status => 409 and return
      end
    end
  end

  def unlock
    logger.warn "unlock"
    lock = request.headers["X-WOPI-Lock"]
    if lock.nil? || lock.blank?
      render :nothing => true, :status => 400 and return
    end
    @asset.with_lock do
      if @asset.is_locked
        logger.warn "Current asset lock: #{@asset.lock}, unlocking lock #{lock}"
        if @asset.lock == lock
          @asset.unlock
          response.headers["X-WOPI-ItemVersion"] = @asset.version
          render :nothing => true, :status => 200 and return
        else
          response.headers["X-WOPI-Lock"] = @asset.lock
          render :nothing => true, :status => 409 and return
        end
      else
        logger.warn "Tried to unlock non-locked file"
        response.headers["X-WOPI-Lock"] = " "
        render :nothing => true, :status => 409 and return
      end
    end
  end

  def refresh_lock
    logger.warn "refresh lock"
    lock = request.headers["X-WOPI-Lock"]
    if lock.nil? || lock.blank?
      render :nothing => true, :status => 400 and return
    end
    @asset.with_lock do
      if @asset.is_locked
        if @asset.lock == lock
          @asset.refresh_lock
          response.headers["X-WOPI-ItemVersion"] = @asset.version
          response.headers["X-WOPI-ItemVersion"] = @asset.version
          render :nothing => true, :status => 200 and return
        else
          response.headers["X-WOPI-Lock"] = @asset.lock
          render :nothing => true, :status => 409 and return
        end
      else
        response.headers["X-WOPI-Lock"] = ""
        render :nothing => true, :status => 409 and return
      end
    end
  end

  def get_lock
    logger.warn "get lock"
    @asset.with_lock do
      if @asset.is_locked
          response.headers["X-WOPI-Lock"] = @asset.lock
          render :nothing => true, :status => 200 and return
      else
        response.headers["X-WOPI-Lock"] = ""
        render :nothing => true, :status => 200 and return
      end
    end
  end
 # TODO When should we extract file text?
  def put_file
    logger.warn "put file"
    @asset.with_lock do
      lock = request.headers["X-WOPI-Lock"]
      if @asset.is_locked
        if @asset.lock == lock
          logger.warn "replacing file"
          @asset.update_contents(request.body)
          response.headers["X-WOPI-ItemVersion"] = @asset.version
          render :nothing => true, :status => 200 and return
        else
          logger.warn "wrong lock used to try and modify file"
          response.headers["X-WOPI-Lock"] = @asset.lock
          render :nothing => true, :status => 409 and return
        end
      else
        if !@asset.file_file_size.nil? and @asset.file_file_size==0
          logger.warn "initializing empty file"
          @asset.update_contents(request.body)
          response.headers["X-WOPI-ItemVersion"] = @asset.version
          render :nothing => true, :status => 200 and return
        else
          logger.warn "trying to modify unlocked file"
          response.headers["X-WOPI-Lock"] = ""
          render :nothing => true, :status => 409 and return
        end
      end
    end
  end


  def load_vars
    @asset = Asset.find_by_id(params[:id])
    if @asset.nil?
      render :nothing => true, :status => 404 and return
    else
      logger.warn "Found asset"
      step_assoc = @asset.step
      result_assoc = @asset.result
      @assoc = step_assoc if not step_assoc.nil?
      @assoc = result_assoc if not result_assoc.nil?

      if @assoc.class == Step
        @protocol = @asset.step.protocol
      else
        @my_module = @assoc.my_module
      end
    end
  end

  private
    def authenticate_user_from_token!
      wopi_token = params[:access_token]
      if wopi_token.nil?
        logger.warn "nil wopi token"
        render :nothing => true, :status => 401 and return
      end

      @user = User.find_by_valid_wopi_token(wopi_token)
      if @user.nil?
        logger.warn "no user with this token found"
        render :nothing => true, :status => 401 and return
      end
      logger.warn "user found by token"

      #TODO check if the user can do anything with the file
    end

    def verify_proof!
      begin
        token = params[:access_token].encode('utf-8')
        timestamp = request.headers['X-WOPI-TimeStamp'].to_i
        signed_proof = request.headers['X-WOPI-Proof']
        signed_proof_old = request.headers['X-WOPI-ProofOld']
        url = request.original_url.upcase.encode('utf-8')

        if convert_to_unix_timestamp(timestamp) + 20.minutes >= Time.now
          if get_discovery.verify_proof(token, timestamp, signed_proof,
                                        signed_proof_old, url)
            logger.warn 'Proof verification: successful'
          else
            logger.warn 'Proof verification: not verified'
            render :nothing => true, :status => 500 and return
          end
        else
          logger.warn 'Proof verification: timestamp too old; ' + timestamp.to_s
          render :nothing => true, :status => 500 and return
        end
      rescue => e
        logger.warn 'Proof verification: failed; ' + e.message
        render :nothing => true, :status => 500 and return
      end
    end

end
