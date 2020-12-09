# frozen_string_literal: true

module RepositoryColumnsHelper
  def defined_delimiters_options
    (%i(auto) + Constants::REPOSITORY_LIST_ITEMS_DELIMITERS_MAP.keys)
      .map { |e| Hash[t('libraries.manange_modal_column.list_type.delimiters.' + e.to_s), e] }
      .inject(:merge)
  end
end
