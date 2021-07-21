module Users
  module Settings
    module Account
      class AddonsController < ApplicationController
        layout 'fluid'

        before_action :load_printers, only: :index

        def label_printer
          @printer = {printer_type: :fluics, ready: true, api_key: 'ISVO42192IUDV168ATFI314UVYGU151USHYEV42'}
        end

        private

        def load_printers
          @fluics_printer = {ready: true, enabled: true}
        end
      end
    end
  end
end
