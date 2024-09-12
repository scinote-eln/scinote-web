# frozen_string_literal: true

module Cloneable
  extend ActiveSupport::Concern

  def next_clone_name
    raise NotImplementedError, "Cloneable model must implement the '.parent' method!" unless respond_to?(:parent)

    clone_label = I18n.t('general.clone_label')

    records = if parent
                parent.public_send(self.class.table_name)
              else
                self.class.where(parent_id: nil, team: team)
              end

    last_clone_number = records
                        .select("substring(#{self.class.table_name}.name, '(?:^#{clone_label} )(\\d+)')::int AS clone_number")
                        .where('name ~ ?', "^#{clone_label} \\d+ - #{Regexp.escape(name)}$")
                        .order(clone_number: :asc)
                        .last&.clone_number

    "#{clone_label} #{(last_clone_number || 0) + 1} - #{name}".truncate(Constants::NAME_MAX_LENGTH)
  end
end
