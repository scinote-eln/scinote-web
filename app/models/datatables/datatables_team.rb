module Datatables
  class DatatablesTeam < ApplicationRecord
    belongs_to :user
    private

    # this isn't strictly necessary, but it will prevent
    # rails from calling save, which would fail anyway.
    def readonly?
      true
    end
  end
end
