# frozen_string_literal: true

class EquipmentBookingsController < ApplicationController
  before_action :set_breadcrumbs_items, only: :index

  def index; end

  private

  def set_breadcrumbs_items
    @breadcrumbs_items = [
      { label: t('breadcrumbs.equipment_bookings'), url: nil }
    ]
  end
end
