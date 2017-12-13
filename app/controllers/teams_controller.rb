class TeamsController < ApplicationController
  before_action :load_vars, only: [:parse_sheet, :import_samples, :export_samples]

  before_action :check_create_sample_permissions, only: [:parse_sheet, :import_samples]
  before_action :check_view_samples_permission, only: [:export_samples]

  def parse_sheet
    session[:return_to] ||= request.referer

    unless params[:file]
      return parse_sheet_error(t('teams.parse_sheet.errors.no_file_selected'))
    end
    if params[:file].size > Constants::FILE_MAX_SIZE_MB.megabytes
      error = t('general.file.size_exceeded',
                file_size: Constants::FILE_MAX_SIZE_MB)
      return parse_sheet_error(error)
    end

    begin
      sheet = SpreadsheetParser.open_spreadsheet(params[:file])
      @header, @columns = SpreadsheetParser.first_two_rows(sheet)

      if @header.empty? || @columns.empty?
        return parse_sheet_error(t('teams.parse_sheet.errors.empty_file'))
      end

      # Fill in fields for dropdown
      @available_fields = @team.get_available_sample_fields
      # Truncate long fields
      @available_fields.update(@available_fields) do |_k, v|
        v.truncate(Constants::NAME_TRUNCATION_LENGTH_DROPDOWN)
      end

      # Save file for next step (importing)
      @temp_file = TempFile.new(
        session_id: session.id,
        file: params[:file]
      )

      if @temp_file.save
        @temp_file.destroy_obsolete
        respond_to do |format|
          format.json do
            render json: {
              html: render_to_string(
                partial: 'samples/parse_samples_modal.html.erb'
              )
            }
          end
        end
      else
        return parse_sheet_error(
          t('teams.parse_sheet.errors.temp_file_failure')
        )
      end
    rescue ArgumentError, CSV::MalformedCSVError
      return parse_sheet_error(t('teams.parse_sheet.errors.invalid_file',
                                 encoding: ''.encoding))
    rescue TypeError
      return parse_sheet_error(t('teams.parse_sheet.errors.invalid_extension'))
    end
  end

  def import_samples
    session[:return_to] ||= request.referer

    respond_to do |format|
      if params[:file_id]
        @temp_file = TempFile.find_by_id(params[:file_id])

        if @temp_file
          # Check if session_id is equal to prevent file stealing
          if @temp_file.session_id == session.id
            # Check if mappings exists or else we don't have anything to parse
            if params[:mappings]
              @sheet = SpreadsheetParser.open_spreadsheet(@temp_file.file)

              # Check for duplicated values
              h1 = params[:mappings].clone.delete_if { |k, v| v.empty? }
              if h1.length == h1.invert.length

                # Check if there exist mapping for sample name (it's mandatory)
                if params[:mappings].has_value?("-1")
                  result = @team.import_samples(@sheet, params[:mappings], current_user)
                  nr_of_added = result[:nr_of_added]
                  total_nr = result[:total_nr]

                  if result[:status] == :ok
                    # If no errors are present, redirect back
                    # to samples table
                    flash[:success] = t(
                      "teams.import_samples.success_flash",
                      nr: nr_of_added,
                      samples: t(
                        "teams.import_samples.sample",
                        count: total_nr
                      )
                    )
                    @temp_file.destroy
                    format.html {
                      redirect_to session.delete(:return_to)
                    }
                    format.json {
                      flash.keep(:success)
                      render json: { status: :ok }
                    }
                  else
                    # Otherwise, also redirect back,
                    # but display different message
                    flash[:alert] = t(
                      "teams.import_samples.partial_success_flash",
                      nr: nr_of_added,
                      samples: t(
                        "teams.import_samples.sample",
                        count: total_nr
                      )
                    )
                    @temp_file.destroy
                    format.html {
                      redirect_to session.delete(:return_to)
                    }
                    format.json {
                      flash.keep(:alert)
                      render json: { status: :unprocessable_entity }
                    }
                  end
                else
                  # This is currently the only AJAX error response
                  flash_alert = t(
                    "teams.import_samples.errors.no_sample_name")
                  format.html {
                    flash[:alert] = flash_alert
                    redirect_to session.delete(:return_to)
                  }
                  format.json {
                    render json: {
                      html: render_to_string({
                        partial: "parse_error.html.erb",
                        locals: { error: flash_alert }
                      })
                    },
                    status: :unprocessable_entity
                  }
                end
              else
                # This code should never execute unless user tampers with
                # JS (selects same column in more than one dropdown)
                flash_alert = t(
                  "teams.import_samples.errors.duplicated_values")
                format.html {
                  flash[:alert] = flash_alert
                  redirect_to session.delete(:return_to)
                }
                format.json {
                  render json: {
                    html: render_to_string({
                      partial: "parse_error.html.erb",
                      locals: { error: flash_alert }
                    })
                  },
                  status: :unprocessable_entity
                }
              end
            else
              @temp_file.destroy
              flash[:alert] = t(
                "teams.import_samples.errors.no_data_to_parse")
              format.html {
                redirect_to session.delete(:return_to)
              }
              format.json {
                flash.keep(:alert)
                render json: { status: :unprocessable_entity }
              }
            end
          else
            @temp_file.destroy
            flash[:alert] = t(
              "teams.import_samples.errors.session_expired")
            format.html {
              redirect_to session.delete(:return_to)
            }
            format.json {
              flash.keep(:alert)
              render json: { status: :unprocessable_entity }
            }
          end
        else
          # No temp file to begin with, so no need to destroy it
          flash[:alert] = t(
            "teams.import_samples.errors.temp_file_not_found")
          format.html {
            redirect_to session.delete(:return_to)
          }
          format.json {
            flash.keep(:alert)
            render json: { status: :unprocessable_entity }
          }
        end
      else
        flash[:alert] = t(
          "teams.import_samples.errors.temp_file_not_found")
        format.html {
          redirect_to session.delete(:return_to)
        }
        format.json {
          flash.keep(:alert)
          render json: { status: :unprocessable_entity }
        }
      end
    end
  end

  def export_samples
    if params[:sample_ids] && params[:header_ids]
      generate_samples_zip
    else
      flash[:alert] = t('zip_export.export_error')
    end
    redirect_to :back
  end

  def routing_error(error = 'Routing error', status = :not_found, exception=nil)
    redirect_to root_path
  end

  private

  def parse_sheet_error(error)
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

  def load_vars
    @team = Team.find_by_id(params[:id])

    unless @team
      render_404
    end
  end

  def check_create_sample_permissions
    unless can_create_sample?(@team)
      render_403
    end
  end

  def check_view_samples_permission
    unless can_read_team?(@team)
      render_403
    end
  end

  def generate_samples_zip
    zip = ZipExport.create(user: current_user)
    zip.generate_exportable_zip(
      current_user,
      @team.to_csv(Sample.where(id: params[:sample_ids]), params[:header_ids]),
      :samples
    )
  end
end
