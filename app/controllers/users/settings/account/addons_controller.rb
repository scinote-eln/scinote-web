module Users
  module Settings
    module Account
      class AddonsController < ApplicationController
        layout 'fluid'

        def index
          @label_printers = LabelPrinter.all
        end
      end
    end
  end
end
