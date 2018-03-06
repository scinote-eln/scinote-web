module Views
  module Datatables
    class SearchRepository < ApplicationRecord
      belongs_to :repository
      # def self.records(repository, search_value)
      #   # binding.pry
      #   # # where('repository_rows.repository_id', repository.id).to_a
      #   # where(repository_id: repository.id)
      #   # .where()
      # end

      private

      # this isn't strictly necessary, but it will prevent
      # rails from calling save, which would fail anyway.
      def readonly?
        true
      end
    end
  end
end
