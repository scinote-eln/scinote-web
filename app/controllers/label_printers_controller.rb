# frozen_string_literal: true

class LabelPrintersController < ApplicationController
  include InputSanitizeHelper

  before_action :check_manage_permissions, except: %i(index index_zebra update_progress_modal)
  before_action :find_label_printer, only: %i(edit update destroy)
  before_action :set_breadcrumbs_items, only: %i(index_zebra index)

  def index
    @label_printers = LabelPrinter.all
    @fluics_api_key = @label_printers.any? ? @label_printers.first.fluics_api_key : nil
    @printer_type = 'fluics'
    respond_to do |format|
      format.json do
        render json: @label_printers, each_serializer: LabelPrinterSerializer, user: current_user
      end
      format.html do
        render 'index'
      end
    end
  end

  def index_zebra
    @printer_type = 'zebra'
    render 'index'
  end

  def new
    @label_printer = LabelPrinter.new
  end

  def edit; end

  def create
    @label_printer = LabelPrinter.new(label_printer_params)

    if @label_printer.save
      flash[:success] = t('label_printers.create.success',  printer_name: @label_printer.name)
      redirect_to edit_label_printer_path(@label_printer)
    else
      flash[:error] = t('label_printers.create.error',  printer_name: @label_printer.name)
      render :new
    end
  end

  def update
    if @label_printer.update(label_printer_params)
      flash[:success] = t('label_printers.update.success',  printer_name: @label_printer.name)
      redirect_to edit_label_printer_path(@label_printer)
    else
      flash[:error] = t('label_printers.update.error',  printer_name: @label_printer.name)
      render :edit
    end
  end

  def destroy
    if @label_printer.destroy
      flash[:success] = t('label_printers.destroy.success',  printer_name: @label_printer.name)
    else
      flash[:error] = t('label_printers.destroy.error',  printer_name: @label_printer.name)
    end

    redirect_to addons_path
  end

  def print
    print_job = LabelPrinters::PrintJob.perform_later(
      LabelPrinter.find(params[:id]),
      LabelTemplate.find(print_job_params[:label_template_id])
        .render(print_job_params[:locals])
    )

    render json: { job_id: print_job.job_id }
  end

  def update_progress_modal
    render(
      json: {
        html:
          render_to_string(
            partial: 'label_printers/print_progress_modal',
            locals: {
              starting_item_count: params[:starting_item_count].to_i,
              label_printer: LabelPrinter.find(params[:id])
            }
          )
      }
    )
  end

  def create_fluics
    begin
      printers = LabelPrinters::Fluics::ApiClient.new(label_printer_params[:fluics_api_key]).list

      LabelPrinter.destroy_all

      printers.each do |fluics_printer|
        label_printer = LabelPrinter.find_or_initialize_by(
          fluics_api_key: label_printer_params[:fluics_api_key],
          fluics_lid: fluics_printer['LID'],
          type_of: :fluics,
          language_type: :zpl
        )

        label_printer.update(
          name: fluics_printer['serviceName'],
          description: fluics_printer['comment']
        )
      end
    rescue LabelPrinters::Fluics::ApiClient::BadRequestError
      flash[:error] = t('users.settings.account.label_printer.api_key_error')
    end

    redirect_to label_printers_path
  end

  private

  def check_manage_permissions
    render_403 unless can_manage_label_printers?
  end

  def label_printer_params
    params.require(:label_printer).permit(
      :name, :type_of, :fluics_api_key, :host, :port
    )
  end

  def print_job_params
    params.require(:label_template_id, :label_template_locals)
  end

  def find_label_printer
    @label_printer = LabelPrinter.find(params[:id])
  end

  def set_breadcrumbs_items
    @breadcrumbs_items = []
    printer_label = t('breadcrumbs.fluics_printer')
    printer_label = t('breadcrumbs.label_printer') if action_name == 'index_zebra'

    @breadcrumbs_items.push({
                              label: t('breadcrumbs.addons'),
                              url: addons_path
                            })
    if @label_printer
      @breadcrumbs_items.push({
                                label: @label_printer.name,
                                url: label_printers_path(@label_printer)
                              })
    else
      @breadcrumbs_items.push({
                                label: printer_label
                              })
    end
  end
end
