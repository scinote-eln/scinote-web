class WopiController < ActionController::Base
    before_action :authenticate_user_from_token!, :load_vars
    #before_action :verify_proof!

  def get_file
    Rails.logger.warn "get_file called"
    #Only used for checkfileinfo
    check_file_info
  end

  def get_file_contents
    Rails.logger.warn "get_file_contents called"
    #Only used for getfile
    get_file

  end

  def post_file
    Rails.logger.warn "post_file called"
    override = request.headers["X-WOPI-Override"]
    case override
      when "PUT_RELATIVE"
        put_relative
      when "LOCK"
        lock
      when "UNLOCK"
        unlock
      when "REFRESH_LOCK"
        refresh_lock
      else
        render :nothing => true, :status => 404 and return
      end
  end

  def post_file_contents
    Rails.logger.warn "post_file_contents called"
    #Only used for putfile
    put_file
  end

  def check_file_info
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
            :UserCanWrite => true,
            #TODO decide what to put here
            :CloseUrl => "",
            :DownloadUrl => url_for(controller: 'assets',action: 'download',id: @asset.id),
            :HostEditUrl => url_for(controller: 'assets',action: 'edit',id: @asset.id),
            :HostViewUrl => url_for(controller: 'assets',action: 'view',id: @asset.id)
            #TODO breadcrumbs?
            #:FileExtension
          }
      render json:msg
  end



  def load_vars
    @asset = Asset.find_by_id(params[:id])
    if @asset.nil?
      render :nothing => true, :status => 404 and return
    else
      Rails.logger.warn "Found asset with id: #{params[:id]}, (id: #{@asset.id})"
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
        Rails.logger.warn "nil wopi token"
        render :nothing => true, :status => 401 and return
      end

      @user = User.find_by_valid_wopi_token(wopi_token)
      if @user.nil?
        Rails.logger.warn "no user with this token found"
        render :nothing => true, :status => 401 and return
      end

      #TODO check if the user can do anything with the file
    end

    def verify_proof!
      begin
        token = params[:access_token]
        timestamp = request.headers["X-WOPI-TimeStamp"]
        url = request.original_url

        token_length = [token.length].pack('N').bytes
        timestamp_bytes = [timestamp.to_i].pack('Q').bytes.reverse
        timestamp_length = [timestamp_bytes.length].pack('N').bytes
        url_length = [url.length].pack('N').bytes

        proof = token_length + token.bytes + url_length + url.bytes + timestamp_length + timestamp_bytes

        Rails.logger.warn "PROOF: #{proof}"

        xml_doc  = Nokogiri::XML("<root><aliens><alien><name>Alf</name></alien></aliens></root>")
      rescue
        Rails.logger.warn "proof verification failed"
        render :nothing => true, :status => 401 and return
      end


    end

end