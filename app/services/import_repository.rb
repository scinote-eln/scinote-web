class ImportRepository

  def initialize(options)
    @file = options.fetch(:file)
    @repository = options.fetch(:repository)
    @sheet = @repository.open_spreadsheet(@file )
  end

  def data
    # Get data (it will trigger any errors as well)
    header = @sheet.row(1)
    rows = []
    rows << Hash[[header, @sheet.row(2)].transpose]

    # Fill in fields for dropdown
    available_fields = @repository.available_repository_fields.map do |name|
      name.truncate(Constants::NAME_TRUNCATION_LENGTH_DROPDOWN)
    end
    { header: header, rows: rows, available_fields: available_fields }
  end

  def check_file_size
    return unless @file.size > Constants::FILE_MAX_SIZE_MB.megabytes
    respond_to do |format|
      error = t('general.file.size_exceeded',
                file_size: Constants::FILE_MAX_SIZE_MB)

      format.html do
        flash[:alert] = error
        redirect_to session.delete(:return_to)
      end
      format.json do
        render json: { message: error },
          status: :unprocessable_entity
      end
    end
  end

  def check_spreadsheet_rows(sheet)
    if @sheet.last_row.between?(0, 1)
      flash[:notice] = t('teams.parse_sheet.errors.empty_file')
      redirect_to session.delete(:return_to) and return
    end
  end

  def generate_temp_file
    # Save file for next step (importing)
    @temp_file = TempFile.new(
      session_id: session.id,
      file: @file
    )
    respond_to do |format|
      if @temp_file.save
        @temp_file.destroy_obsolete
        # format.html
        format.json do
          render json: {
            html: render_to_string({
              partial: 'samples/parse_samples_modal.html.erb'
            })
          }
        end
      else
        error = t('teams.parse_sheet.errors.temp_file_failure')
        format.html do
          flash[:alert] = error
          redirect_to session.delete(:return_to)
        end
        format.json do
          render json: { message: error },
            status: :unprocessable_entity
        end
      end
    end
  end

  def argument_error_callback
    error = t('teams.parse_sheet.errors.invalid_file',
              encoding: ''.encoding)
    respond_to do |format|
      format.html do
        flash[:alert] = error
        redirect_to session.delete(:return_to)
      end
      format.json do
        render json: { message: error },
          status: :unprocessable_entity
      end
    end
  end

  def type_error_callback
    error = t('teams.parse_sheet.errors.invalid_extension')
    respond_to do |format|
      format.html do
        flash[:alert] = error
        redirect_to session.delete(:return_to)
      end
      format.json do
        render json: {message: error},
          status: :unprocessable_entity
      end
    end
  end

  def no_file_callback
    error = t('teams.parse_sheet.errors.no_file_selected')
    respond_to do |format|
      format.html do
        flash[:alert] = error
        session[:return_to] ||= request.referer
        redirect_to session.delete(:return_to)
      end
      format.json do
        render json: { message: error },
          status: :unprocessable_entity
      end
    end
  end

  # def import_repository
  #   session[:return_to] ||= request.referer
  #
  #   respond_to do |format|
  #     if params[:file_id]
  #       @temp_file = TempFile.find_by_id(params[:file_id])
  #
  #       if @temp_file
  #         # Check if session_id is equal to prevent file stealing
  #         if @temp_file.session_id == session.id
  #           # Check if mappings exists or else we don't have anything to parse
  #           if params[:mappings]
  #             @sheet = Team.open_spreadsheet(@temp_file.file)
  #
  #             # Check for duplicated values
  #             h1 = params[:mappings].clone.delete_if { |k, v| v.empty? }
  #             if h1.length == h1.invert.length
  #
  #               # Check if there exist mapping for sample name (it's mandatory)
  #               if params[:mappings].has_value?("-1")
  #                 result = @team.import_samples(@sheet, params[:mappings], current_user)
  #                 nr_of_added = result[:nr_of_added]
  #                 total_nr = result[:total_nr]
  #
  #                 if result[:status] == :ok
  #                   # If no errors are present, redirect back
  #                   # to samples table
  #                   flash[:success] = t(
  #                     "teams.import_samples.success_flash",
  #                     nr: nr_of_added,
  #                     samples: t(
  #                       "teams.import_samples.sample",
  #                       count: total_nr
  #                     )
  #                   )
  #                   @temp_file.destroy
  #                   format.html {
  #                     redirect_to session.delete(:return_to)
  #                   }
  #                   format.json {
  #                     flash.keep(:success)
  #                     render json: { status: :ok }
  #                   }
  #                 else
  #                   # Otherwise, also redirect back,
  #                   # but display different message
  #                   flash[:alert] = t(
  #                     "teams.import_samples.partial_success_flash",
  #                     nr: nr_of_added,
  #                     samples: t(
  #                       "teams.import_samples.sample",
  #                       count: total_nr
  #                     )
  #                   )
  #                   @temp_file.destroy
  #                   format.html {
  #                     redirect_to session.delete(:return_to)
  #                   }
  #                   format.json {
  #                     flash.keep(:alert)
  #                     render json: { status: :unprocessable_entity }
  #                   }
  #                 end
  #               else
  #                 # This is currently the only AJAX error response
  #                 flash_alert = t(
  #                   "teams.import_samples.errors.no_sample_name")
  #                 format.html {
  #                   flash[:alert] = flash_alert
  #                   redirect_to session.delete(:return_to)
  #                 }
  #                 format.json {
  #                   render json: {
  #                     html: render_to_string({
  #                       partial: "parse_error.html.erb",
  #                       locals: { error: flash_alert }
  #                     })
  #                   },
  #                   status: :unprocessable_entity
  #                 }
  #               end
  #             else
  #               # This code should never execute unless user tampers with
  #               # JS (selects same column in more than one dropdown)
  #               flash_alert = t(
  #                 "teams.import_samples.errors.duplicated_values")
  #               format.html {
  #                 flash[:alert] = flash_alert
  #                 redirect_to session.delete(:return_to)
  #               }
  #               format.json {
  #                 render json: {
  #                   html: render_to_string({
  #                     partial: "parse_error.html.erb",
  #                     locals: { error: flash_alert }
  #                   })
  #                 },
  #                 status: :unprocessable_entity
  #               }
  #             end
  #           else
  #             @temp_file.destroy
  #             flash[:alert] = t(
  #               "teams.import_samples.errors.no_data_to_parse")
  #             format.html {
  #               redirect_to session.delete(:return_to)
  #             }
  #             format.json {
  #               flash.keep(:alert)
  #               render json: { status: :unprocessable_entity }
  #             }
  #           end
  #         else
  #           @temp_file.destroy
  #           flash[:alert] = t(
  #             "teams.import_samples.errors.session_expired")
  #           format.html {
  #             redirect_to session.delete(:return_to)
  #           }
  #           format.json {
  #             flash.keep(:alert)
  #             render json: { status: :unprocessable_entity }
  #           }
  #         end
  #       else
  #         # No temp file to begin with, so no need to destroy it
  #         flash[:alert] = t(
  #           "teams.import_samples.errors.temp_file_not_found")
  #         format.html {
  #           redirect_to session.delete(:return_to)
  #         }
  #         format.json {
  #           flash.keep(:alert)
  #           render json: { status: :unprocessable_entity }
  #         }
  #       end
  #     else
  #       flash[:alert] = t(
  #         "teams.import_samples.errors.temp_file_not_found")
  #       format.html {
  #         redirect_to session.delete(:return_to)
  #       }
  #       format.json {
  #         flash.keep(:alert)
  #         render json: { status: :unprocessable_entity }
  #       }
  #     end
  #   end
  # end
  #
  # def parse_sheet
  #   session[:return_to] ||= request.referer
  #
  #   respond_to do |format|
  #     if params[:file]
  #       begin
  #
  #         if params[:file].size > Constants::FILE_MAX_SIZE_MB.megabytes
  #           error = t 'general.file.size_exceeded',
  #                     file_size: Constants::FILE_MAX_SIZE_MB
  #
  #           format.html {
  #             flash[:alert] = error
  #             redirect_to session.delete(:return_to)
  #           }
  #           format.json {
  #             render json: {message: error},
  #               status: :unprocessable_entity
  #           }
  #
  #         else
  #           sheet = Team.open_spreadsheet(params[:file])
  #
  #           # Check if we actually have any rows (last_row > 1)
  #           if sheet.last_row.between?(0, 1)
  #             flash[:notice] = t(
  #               "teams.parse_sheet.errors.empty_file")
  #             redirect_to session.delete(:return_to) and return
  #           end
  #
  #           # Get data (it will trigger any errors as well)
  #           @header = sheet.row(1)
  #           @rows = [];
  #           @rows << Hash[[@header, sheet.row(2)].transpose]
  #
  #           # Fill in fields for dropdown
  #           @available_fields = @team.get_available_sample_fields
  #           # Truncate long fields
  #           @available_fields.update(@available_fields) do |_k, v|
  #             v.truncate(Constants::NAME_TRUNCATION_LENGTH_DROPDOWN)
  #           end
  #
  #           # Save file for next step (importing)
  #           @temp_file = TempFile.new(
  #             session_id: session.id,
  #             file: params[:file]
  #           )
  #
  #           if @temp_file.save
  #             @temp_file.destroy_obsolete
  #             # format.html
  #             format.json {
  #               render :json => {
  #                 :html => render_to_string({
  #                   :partial => "samples/parse_samples_modal.html.erb"
  #                 })
  #               }
  #             }
  #           else
  #             error = t("teams.parse_sheet.errors.temp_file_failure")
  #             format.html {
  #               flash[:alert] = error
  #               redirect_to session.delete(:return_to)
  #             }
  #             format.json {
  #               render json: {message: error},
  #                 status: :unprocessable_entity
  #             }
  #           end
  #         end
  #       rescue ArgumentError, CSV::MalformedCSVError
  #         error = t('teams.parse_sheet.errors.invalid_file',
  #                   encoding: ''.encoding)
  #         format.html {
  #           flash[:alert] = error
  #           redirect_to session.delete(:return_to)
  #         }
  #         format.json {
  #           render json: {message: error},
  #             status: :unprocessable_entity
  #         }
  #       rescue TypeError
  #         error =  t("teams.parse_sheet.errors.invalid_extension")
  #         format.html {
  #           flash[:alert] = error
  #           redirect_to session.delete(:return_to)
  #         }
  #         format.json {
  #           render json: {message: error},
  #             status: :unprocessable_entity
  #         }
  #       end
  #     else
  #       error = t("teams.parse_sheet.errors.no_file_selected")
  #       format.html {
  #         flash[:alert] = error
  #         session[:return_to] ||= request.referer
  #         redirect_to session.delete(:return_to)
  #       }
  #       format.json {
  #         render json: {message: error},
  #           status: :unprocessable_entity
  #       }
  #     end
  #   end
  # end
end
