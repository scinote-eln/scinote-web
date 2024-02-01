# frozen_string_literal: true

module Users
  module Settings
    module Account
      class AddonsController < ApplicationController
        before_action :set_breadcrumbs_items, only: %i(index)
        layout 'fluid'

        def index
          @label_printer_any = LabelPrinter.any?
          @user_agent = request.user_agent
        end

        private

        def set_breadcrumbs_items
          @breadcrumbs_items = []
          @breadcrumbs_items.push({
                                    label: t('breadcrumbs.addons'),
                                    url: addons_path
                                  })
        end
      end
    end
  end
end
