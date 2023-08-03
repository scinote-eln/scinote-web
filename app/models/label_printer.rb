# frozen_string_literal: true

class LabelPrinter < ApplicationRecord
  FLUICS_STATUS_MAP = Hash.new(:error).merge(
    {
      '00' => :ready,
      '50' => :busy,
      '60' => :busy,
      '01' => :out_of_labels,
      '02' => :out_of_labels
    }
  ).freeze

  enum type_of: { fluics: 0 }
  enum language_type: { zpl: 0 }
  enum status: { ready: 0, busy: 1, out_of_labels: 2, unreachable: 3, error: 4 }

  validates :name, presence: true
  validates :type_of, presence: true
  validates :language_type, presence: true

  def done?
    current_print_job_ids.blank? && ready?
  end

  def printing?
    current_print_job_ids.any? && ready?
  end

  def printing_status
    return 'printing' if printing?

    return 'done' if done?

    status
  end
end
