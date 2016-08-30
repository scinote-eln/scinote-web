class Organization < ActiveRecord::Base
  # Not really MVC-compliant, but we just use it for logger
  # output in space_taken related functions
  include ActionView::Helpers::NumberHelper

  validates :name,
    presence: { message: '' },
    length: { minimum: 4, maximum: 100, message: '' }
  validates :space_taken,
    presence: true

  belongs_to :created_by, :foreign_key => 'created_by_id', :class_name => 'User'
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'
  has_many :user_organizations, inverse_of: :organization, dependent: :destroy
  has_many :users, through: :user_organizations
  has_many :samples, inverse_of: :organization
  has_many :sample_groups, inverse_of: :organization
  has_many :sample_types, inverse_of: :organization
  has_many :logs, inverse_of: :organization
  has_many :projects, inverse_of: :organization
  has_many :custom_fields, inverse_of: :organization
  has_many :protocols, inverse_of: :organization, dependent: :destroy
  has_many :protocol_keywords, inverse_of: :organization, dependent: :destroy

  # Based on file's extension opens file (used for importing)
  def self.open_spreadsheet(file)
    filename = file.original_filename
    file_path = file.path

    if file.class == Paperclip::Attachment and file.is_stored_on_s3?
      fa = file.fetch
      file_path = fa.path
    end

    case File.extname(filename)
    when ".csv" then
      Roo::CSV.new(file_path, extension: :csv)
    when ".tdv" then
      Roo::CSV.new(file_path, nil, :ignore, csv_options: {col_sep: "\t"})
    when ".txt" then
      # This assumption is based purely on biologist's habits
      Roo::CSV.new(file_path, csv_options: {col_sep: "\t"})
    when ".xls" then
      Roo::Excel.new(file_path)
    when ".xlsx" then
      Roo::Excelx.new(file_path)
    else
      raise TypeError
    end
  end

  # Writes to user log.
  def log(message)
    final = "[%s] %s" % [Time.current.to_s, message]
    logs.create(message: final)
  end

  # Imports samples into db
  # -1 == sample_name,
  # -2 == sample_type,
  # -3 == sample_group
  # TODO: use constants
  def import_samples(sheet, mappings, user)
    errors = []
    nr_of_added = 0
    total_nr = 0

    # First let's query for all custom_fields we're refering to
    custom_fields = []
    sname_index = -1
    stype_index = -1
    sgroup_index = -1
    mappings.each.with_index do |(k, v), i|
      if v == "-1"
        # Fill blank space, so our indices stay the same
        custom_fields << nil
        sname_index = i
      elsif v == "-2"
        custom_fields << nil
        stype_index = i
      elsif v == "-3"
        custom_fields << nil
        sgroup_index =  i
      else
        cf = CustomField.find_by_id(v)

        # Even if doesn't exist we add nil value in order not to destroy our
        # indices
        custom_fields << cf
      end
    end

    # Now we can iterate through sample data and save stuff into db
    (2..sheet.last_row).each do |i|
      error = []
      total_nr += 1

      sample = Sample.new(
        name: sheet.row(i)[sname_index],
        organization_id: id,
        user: user
      )

      if sample.save
        sheet.row(i).each.with_index do |value, index|
          # We need to have sample saved before messing with custom fields (they
          # need sample id)
          if index == stype_index
            stype = SampleType.where(name: value, organization_id: id).take();

            if stype
              sample.sample_type = stype
            else
              sample.create_sample_type(
                name: value,
                organization_id: id
              )
            end
            sample.save
          elsif index == sgroup_index
            sgroup = SampleGroup.where(name: value, organization_id: id).take();

            if sgroup
              sample.sample_group = sgroup
            else
              sample.create_sample_group(
                name: value,
                organization_id: id
              )
            end
            sample.save
          elsif value and mappings[index.to_s].strip.present? and index != sname_index
            if custom_fields[index]
              # we're working with CustomField
              scf = SampleCustomField.new(
                sample_id: sample.id,
                custom_field_id: custom_fields[index].id,
                value: value
              )

              if !scf.save
                error << scf.errors.messages
              end
            else
              # This custom_field does not exist
              error << {"#{mappings[index]}": "Does not exists"}
            end
          end
        end
      else
        error << sample.errors.messages
      end
      if error.present?
        errors << { "#{i}": error}
      else
        nr_of_added += 1
      end
    end

    if errors.count > 0 then
      return {
        status: :error,
        errors: errors,
        nr_of_added: nr_of_added,
        total_nr: total_nr
      }
    else
      return {
        status: :ok,
        nr_of_added: nr_of_added,
        total_nr: total_nr
      }
    end
  end

  def to_csv(samples, headers)
    require "csv"

    # Parse headers (magic numbers should be refactored - see
    # sample-datatable.js)
    header_names = []
    headers.each do |header|
      if header == "-1"
        header_names << I18n.t("samples.table.sample_name")
      elsif header == "-2"
        header_names << I18n.t("samples.table.sample_type")
      elsif header == "-3"
        header_names << I18n.t("samples.table.sample_group")
      elsif header == "-4"
        header_names << I18n.t("samples.table.added_by")
      elsif header == "-5"
        header_names << I18n.t("samples.table.added_on")
      else
        cf = CustomField.find_by_id(header)

        if cf
          header_names << cf.name
        else
          header_names << nil
        end
      end
    end

    CSV.generate do |csv|
      csv << header_names
      samples.each do |sample|
        sample_row = []
        headers.each do |header|
          if header == "-1"
            sample_row << sample.name
          elsif header == "-2"
            sample_row << (sample.sample_type.nil? ? I18n.t("samples.table.no_type") : sample.sample_type.name)
          elsif header == "-3"
            sample_row << (sample.sample_group.nil? ? I18n.t("samples.table.no_group") : sample.sample_group.name)
          elsif header == "-4"
            sample_row << sample.user.full_name
          elsif header == "-5"
            sample_row << I18n.l(sample.created_at, format: :full)
          else
            scf = SampleCustomField.where(
              custom_field_id: header,
              sample_id: sample.id
            ).take

            if scf
              sample_row << scf.value
            else
              sample_row << nil
            end
          end
        end
        csv << sample_row
      end
    end
  end

  # Get all header fields for samples (used in importing for mappings - dropdowns)
  def get_available_sample_fields
    fields = {};

    # First and foremost add sample name
    fields["-1"] = I18n.t("samples.table.sample_name")
    fields["-2"] = I18n.t("samples.table.sample_type")
    fields["-3"] = I18n.t("samples.table.sample_group")

    # Add all other custom fields
    CustomField.where(organization_id: id).order(:created_at).each do |cf|
      fields[cf.id] = cf.name
    end

    fields
  end

  # (re)calculate the space taken by this organization
  def calculate_space_taken
    st = 0
    projects.includes(
      experiments: {
        my_modules: {
          protocols: { steps: :assets },
          results: { result_asset: :asset }
        }
      }
    ).find_each do |project|
      project.project_my_modules.find_each do |my_module|
        my_module.protocol.steps.find_each do |step|
          step.assets.find_each { |asset| st += asset.estimated_size }
        end
        my_module.results.find_each do |result|
          if result.is_asset then
            st += result.asset.estimated_size
          end
        end
      end
    end
    # project.experiments.each |experiment|
    self.space_taken = [st, MINIMAL_ORGANIZATION_SPACE_TAKEN].max
    Rails::logger.info "Organization #{self.id}: " +
      "space (re)calculated to: " +
      "#{self.space_taken}B (#{number_to_human_size(self.space_taken)})"
  end

  # Take specified amount of bytes
  def take_space(space)
    orig_space = self.space_taken
    self.space_taken += space
    Rails::logger.info "Organization #{self.id}: " +
      "space taken: " +
      "#{orig_space}B + #{space}B = " +
      "#{self.space_taken}B (#{number_to_human_size(self.space_taken)})"
  end

  # Release specified amount of bytes
  def release_space(space)
    orig_space = self.space_taken
    self.space_taken = [space_taken - space, MINIMAL_ORGANIZATION_SPACE_TAKEN].max
    Rails::logger.info "Organization #{self.id}: " +
      "space released: " +
      "#{orig_space}B - #{space}B = " +
      "#{self.space_taken}B (#{number_to_human_size(self.space_taken)})"
  end

  def protocol_keywords_list
    ProtocolKeyword.where(organization: self).pluck(:name)
  end
end
