module Users
  module Settings
    module Account
      class AddonsController < ApplicationController
        layout 'fluid'

        def index
          @label_printer_any = LabelPrinter.any?
        end
      end
    end
  end
end
