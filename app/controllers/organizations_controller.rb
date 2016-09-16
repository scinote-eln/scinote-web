class OrganizationsController < ApplicationController
  before_action :load_vars, only: [:parse_sheet, :import_samples, :export_samples]

  before_action :check_create_sample_permissions, only: [:parse_sheet, :import_samples]
  before_action :check_view_samples_permission, only: [:export_samples]

  def parse_sheet
    session[:return_to] ||= request.referer

    respond_to do |format|
      if params[:file]
        begin

          if params[:file].size > FILE_MAX_SIZE.megabytes
            error = t("organizations.parse_sheet.errors.file_size_exceeded")
            format.html {
              flash[:alert] = error
              redirect_to session.delete(:return_to)
            }
            format.json {
              render json: {message: error},
                status: :unprocessable_entity
            }

          else
            sheet = Organization.open_spreadsheet(params[:file])

            # Check if we actually have any rows (last_row > 1)
            if sheet.last_row.between?(0, 1)
              flash[:notice] = t(
                "organizations.parse_sheet.errors.empty_file")
              redirect_to session.delete(:return_to) and return
            end

            # Get data (it will trigger any errors as well)
            @header = sheet.row(1)
            @rows = [];
            @rows << Hash[[@header, sheet.row(2)].transpose]

            # Fill in fields for dropdown
            @available_fields = @organization.get_available_sample_fields

            # Save file for next step (importing)
            @temp_file = TempFile.new(
              session_id: session.id,
              file: params[:file]
            )

            if @temp_file.save
              # format.html
              format.json {
                render :json => {
                  :html => render_to_string({
                    :partial => "samples/parse_samples_modal.html.erb"
                  })
                }
              }
            else
              error = t("organizations.parse_sheet.errors.temp_file_failure")
              format.html {
                flash[:alert] = error
                redirect_to session.delete(:return_to)
              }
              format.json {
                render json: {message: error},
                  status: :unprocessable_entity
              }
            end
          end
        rescue ArgumentError, CSV::MalformedCSVError
          error = t("organizations.parse_sheet.errors.invalid_file")
          format.html {
            flash[:alert] = error
            redirect_to session.delete(:return_to)
          }
          format.json {
            render json: {message: error},
              status: :unprocessable_entity
          }
        rescue TypeError
          error =  t("organizations.parse_sheet.errors.invalid_extension")
          format.html {
            flash[:alert] = error
            redirect_to session.delete(:return_to)
          }
          format.json {
            render json: {message: error},
              status: :unprocessable_entity
          }
        end
      else
        error = t("organizations.parse_sheet.errors.no_file_selected")
        format.html {
          flash[:alert] = error
          session[:return_to] ||= request.referer
          redirect_to session.delete(:return_to)
        }
        format.json {
          render json: {message: error},
            status: :unprocessable_entity
        }
      end
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
              @sheet = Organization.open_spreadsheet(@temp_file.file)

              # Check for duplicated values
              h1 = params[:mappings].clone.delete_if { |k, v| v.empty? }
              if h1.length == h1.invert.length

                # Check if there exist mapping for sample name (it's mandatory)
                if params[:mappings].has_value?("-1")
                  result = @organization.import_samples(@sheet, params[:mappings], current_user)
                  nr_of_added = result[:nr_of_added]
                  total_nr = result[:total_nr]

                  if result[:status] == :ok
                    # If no errors are present, redirect back
                    # to samples table
                    flash[:success] = t(
                      "organizations.import_samples.success_flash",
                      nr: nr_of_added,
                      samples: t(
                        "organizations.import_samples.sample",
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
                      "organizations.import_samples.partial_success_flash",
                      nr: nr_of_added,
                      samples: t(
                        "organizations.import_samples.sample",
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
                    "organizations.import_samples.errors.no_sample_name")
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
                  "organizations.import_samples.errors.duplicated_values")
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
                "organizations.import_samples.errors.no_data_to_parse")
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
              "organizations.import_samples.errors.session_expired")
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
            "organizations.import_samples.errors.temp_file_not_found")
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
          "organizations.import_samples.errors.temp_file_not_found")
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
    require "csv"

    respond_to do |format|
      if params[:sample_ids].present? and params[:header_ids].present?
        samples = []

        params[:sample_ids].each do |id|
          sample = Sample.find_by_id(id)

          if sample
            samples << sample
          end
        end
        format.csv { send_data @organization.to_csv(samples, params[:header_ids]) }
      else
        format.csv { render nothing: true }
      end
    end
  end

  def load_vars
    @organization = Organization.find_by_id(params[:id])

    unless @organization
      render_404
    end
  end

  def check_create_sample_permissions
    unless can_create_samples(@organization)
      render_403
    end
  end

  def check_view_samples_permission
    unless can_view_samples(@organization)
      render_403
    end
  end

  def routing_error(error = 'Routing error', status = :not_found, exception=nil)
    redirect_to root_path
  end

end
