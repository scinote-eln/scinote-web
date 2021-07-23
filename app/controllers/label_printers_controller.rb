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

    redirect_to label_printers_path
  end

  private

  def label_printer_params
    params.require(:label_printer).permit(
      :name, :type_of, :fluics_api_key, :host, :port
    )
  end

  def find_label_printer
    @label_printer = LabelPrinter.find(params[:id])
  end
end
