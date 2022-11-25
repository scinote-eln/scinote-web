# frozen_string_literal: true

module Cloneable
  extend ActiveSupport::Concern

  def next_clone_name
    raise NotImplementedError, "Cloneable model must implement the '.parent' method!" unless respond_to?(:parent)

    last_clone_number =
      parent.public_send(self.class.table_name)
            .select("substring(#{self.class.table_name}.name, '(?:^Clone )(\\d)')::int AS clone_number")
            .where('name ~ ?', "^Clone \\d+ - #{name}$")
            .order(clone_number: :asc)
            .last&.clone_number

    "Clone #{(last_clone_number || 0) + 1} - #{name}"
  end
end
