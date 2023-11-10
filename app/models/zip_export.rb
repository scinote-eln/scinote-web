# frozen_string_literal: true

require 'zip'
require 'fileutils'
require 'csv'

class ZipExport < ApplicationRecord
  belongs_to :user, optional: true

  has_one_attached :zip_file

  after_create :self_destruct

  def self.delete_expired_export(id)
    find_by(id: id)&.destroy
  end

  def zip_file_name
    return '' unless zip_file.attached?

    zip_file.blob&.filename&.to_s
  end

  def zip!(input_dir, output_file)
    entries = Dir.glob('**/*', base: input_dir)
    Zip::File.open(output_file, create: true) do |zipfile|
      entries.each do |entry|
        zipfile.add(entry, "#{input_dir}/#{entry}")
      end
    end
  end

  private

  def self_destruct
    ZipExport.delay(run_at: Constants::EXPORTABLE_ZIP_EXPIRATION_DAYS.days.from_now)
             .delete_expired_export(id)
  end
end
