# frozen_string_literal: true

class LabelPrintersController < ApplicationController
  include InputSanitizeHelper

  before_action :find_label_printer, only: %i(edit update destroy)

  def index
    @label_printers = LabelPrinter.all
  end

  def new
    @label_printer = LabelPrinter.new
  end

  def edit; end

  def create
    @label_printer = LabelPrinter.new(label_printer_params)

    if @label_printer.save
      flash[:success] = t('label_printers.create.success', { printer_name: @label_printer.name })
      redirect_to edit_label_printer_path(@label_printer)
    else
      flash[:error] = t('label_printers.create.error', { printer_name: @label_printer.name })
      render :new
    end
  end

  def update
    if @label_printer.update(label_printer_params)
      flash[:success] = t('label_printers.update.success', { printer_name: @label_printer.name })
      redirect_to edit_label_printer_path(@label_printer)
    else
      flash[:error] = t('label_printers.update.error', { printer_name: @label_printer.name })
      render :edit
    end
  end

  def destroy
    if @label_printer.destroy
      flash[:success] = t('label_printers.destroy.success', { printer_name: @label_printer.name })
    else
      flash[:error] = t('label_printers.destroy.error', { printer_name: @label_printer.name })
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

  def create_fluics
    # Placeholder for FLUICS printer management

    LabelPrinters::Fluics::ApiClient.new(params[:fluics_api_key]).list.each do |fluics_printer|
      label_printer = LabelPrinter.find_or_initialize_by(
        fluics_api_key: params[:fluics_api_key],
        fluics_lid: fluics_printer['LID'],
        type_of: :fluics,
        language_type: :zpl
      )

      label_printer.update(name: fluics_printer['serviceName'])
    end

    redirect_to addons_path
  end

  private

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
end
