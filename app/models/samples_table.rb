# frozen_string_literal: true

class SamplesTable < ApplicationRecord
  belongs_to :user, inverse_of: :samples_tables
  belongs_to :team, inverse_of: :samples_tables

  validates :user, :team, presence: true

  scope :find_status, (lambda do |user, team|
                         where(user: user, team: team)
                         .order(:id).pluck(:status).first
                       end)

  def self.update_samples_table_state(custom_field, column_index)
    samples_table = SamplesTable.where(user: custom_field.user,
                                       team: custom_field.team)
                                .order(:id)
                                .first
    team_status = samples_table['status']
    if column_index
      # delete column
      team_status['columns'].delete(column_index)
      team_status['columns'].keys.each do |index|
        if index.to_i > column_index.to_i
          team_status['columns'][(index.to_i - 1).to_s] =
            team_status['columns'].delete(index)
        else
          index
        end
      end
      team_status['ColReorder'].delete(column_index)
      team_status['ColReorder'].map! do |index|
        if index.to_i > column_index.to_i
          (index.to_i - 1).to_s
        else
          index
        end
      end
    else
      # add column
      index = team_status['columns'].count
      team_status['columns'][index] = SampleDatatable::
        SAMPLES_TABLE_DEFAULT_STATE['columns'].first
      team_status['ColReorder'].insert(2, index)
    end
    samples_table.update(status: team_status)
  end

  def self.create_samples_table_state(user_team)
    default_columns_num = SampleDatatable::
                          SAMPLES_TABLE_DEFAULT_STATE['columns'].count
    team_status = SampleDatatable::SAMPLES_TABLE_DEFAULT_STATE.deep_dup
    user_team.team.custom_fields.each_with_index do |_, index|
      team_status['columns'] << SampleDatatable::
                               SAMPLES_TABLE_DEFAULT_STATE['columns'].first
      team_status['ColReorder'] << (default_columns_num + index)
    end
    SamplesTable.create(user: user_team.user,
                        team: user_team.team,
                        status: team_status)
  end
end
