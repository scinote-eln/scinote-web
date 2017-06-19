module ImportRepository
  class ImportRecords
    def initialize(options)
      @temp_file = options.fetch(:temp_file)
      @repository = options.fetch(:repository)
      @mappings = options.fetch(:mappings)
      @session = options.fetch(:session)
      @user = options.fetch(:user)
    end

    def has_temp_file?
      @temp_file
    end

    def session_valid?
      @temp_file.session_id == session.id
    end

    def import!
      unless @mappings
        return { error: t('teams.import_samples.errors.no_data_to_parse') }
      end
      sheet = @repository.open_spreadsheet(@temp_file.file)
      # Check for duplicated values
      h1 = @mappings.clone.delete_if { |k, v| v.empty? }
      unless @mappings.has_value?('-1')
        return { error: t('teams.import_samples.errors.no_sample_name') }
      end
      result = @repository.import_records(sheet, @mappings, @user)
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
