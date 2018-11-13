class Team < ApplicationRecord
  include SearchableModel
  include ViewableModel

  # Not really MVC-compliant, but we just use it for logger
  # output in space_taken related functions
  include ActionView::Helpers::NumberHelper

  auto_strip_attributes :name, :description, nullify: false
  validates :name,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :space_taken, presence: true

  belongs_to :created_by,
             foreign_key: 'created_by_id',
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User',
             optional: true
  has_many :user_teams, inverse_of: :team, dependent: :destroy
  has_many :users, through: :user_teams
  has_many :samples, inverse_of: :team
  has_many :samples_tables, inverse_of: :team, dependent: :destroy
  has_many :sample_groups, inverse_of: :team
  has_many :sample_types, inverse_of: :team
  has_many :projects, inverse_of: :team
  has_many :custom_fields, inverse_of: :team
  has_many :protocols, inverse_of: :team, dependent: :destroy
  has_many :protocol_keywords, inverse_of: :team, dependent: :destroy
  has_many :tiny_mce_assets, inverse_of: :team, dependent: :destroy
  has_many :repositories, dependent: :destroy
  has_many :reports, inverse_of: :team, dependent: :destroy
  has_many :datatables_reports,
           class_name: 'Views::Datatables::DatatablesReport'

  after_commit do
    Views::Datatables::DatatablesReport.refresh_materialized_view
  end

  def default_view_state
    { 'projects' =>
      { 'cards' => { 'sort' => 'new' },
        'table' =>
          { 'time' => Time.now.to_i,
            'order' => [[2, 'asc']],
            'start' => 0,
            'length' => 10 },
        'filter' => 'active' } }
  end

  def search_users(query = nil)
    a_query = "%#{query}%"
    users.where.not(confirmed_at: nil)
         .where('full_name ILIKE ? OR email ILIKE ?', a_query, a_query)
  end

  # Imports samples into db
  # -1 == sample_name,
  # -2 == sample_type,
  # -3 == sample_group
  # TODO: use constants
  def import_samples(sheet, mappings, user)
    errors = false
    nr_of_added = 0
    total_nr = 0
    header_skipped = false

    # First let's query for all custom_fields we're refering to
    custom_fields = []
    sname_index = -1
    stype_index = -1
    sgroup_index = -1
    mappings.each.with_index do |(_, v), i|
      if v == '-1'
        # Fill blank space, so our indices stay the same
        custom_fields << nil
        sname_index = i
      elsif v == '-2'
        custom_fields << nil
        stype_index = i
      elsif v == '-3'
        custom_fields << nil
        sgroup_index = i
      else
        cf = CustomField.find_by_id(v)

        # Even if doesn't exist we add nil value in order not to destroy our
        # indices
        custom_fields << cf
      end
    end

    rows = SpreadsheetParser.spreadsheet_enumerator(sheet)

    # Now we can iterate through sample data and save stuff into db
    rows.each do |row|
      # Skip empty rows
      next if row.empty?
      unless header_skipped
        header_skipped = true
        next
      end
      total_nr += 1
      row = SpreadsheetParser.parse_row(row, sheet)

      sample = Sample.new(name: row[sname_index],
                          team: self,
                          user: user)

      sample.transaction do
        unless sample.valid?
          errors = true
          raise ActiveRecord::Rollback
        end

        row.each.with_index do |value, index|
          next unless value.present?
          if index == stype_index
            stype = SampleType.where(team: self)
                              .where('name ILIKE ?', value.strip)
                              .take

            unless stype
              stype = SampleType.new(name: value.strip, team: self)
              unless stype.save
                errors = true
                raise ActiveRecord::Rollback
              end
            end
            sample.sample_type = stype
          elsif index == sgroup_index
            sgroup = SampleGroup.where(team: self)
                                .where('name ILIKE ?', value.strip)
                                .take

            unless sgroup
              sgroup = SampleGroup.new(name: value.strip, team: self)
              unless sgroup.save
                errors = true
                raise ActiveRecord::Rollback
              end
            end
            sample.sample_group = sgroup
          elsif value && custom_fields[index]
            # we're working with CustomField
            scf = SampleCustomField.new(
              sample: sample,
              custom_field: custom_fields[index],
              value: value
            )
            unless scf.valid?
              errors = true
              raise ActiveRecord::Rollback
            end
            sample.sample_custom_fields << scf
          end
        end
        if Sample.import([sample],
                         recursive: true,
                         validate: false).failed_instances.any?
          errors = true
          raise ActiveRecord::Rollback
        end
        nr_of_added += 1
      end
    end

    if errors
      return { status: :error, nr_of_added: nr_of_added, total_nr: total_nr }
    else
      return { status: :ok, nr_of_added: nr_of_added, total_nr: total_nr }
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
    CustomField.where(team_id: id).order(:created_at).each do |cf|
      fields[cf.id] = cf.name
    end

    fields
  end

  # (re)calculate the space taken by this team
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
          step.tiny_mce_assets.find_each { |tiny| st += tiny.estimated_size }
        end
        my_module.results.find_each do |result|
          st += result.asset.estimated_size if result.is_asset
          if result.is_text
            tiny_assets = TinyMceAsset.where(result_text: result.result_text)
            tiny_assets.find_each { |tiny| st += tiny.estimated_size }
          end
        end
      end
    end
    # project.experiments.each |experiment|
    self.space_taken = [st, Constants::MINIMAL_TEAM_SPACE_TAKEN].max
    Rails::logger.info "Team #{self.id}: " +
      "space (re)calculated to: " +
      "#{self.space_taken}B (#{number_to_human_size(self.space_taken)})"
  end

  # Take specified amount of bytes
  def take_space(space)
    orig_space = self.space_taken
    self.space_taken += space
    Rails::logger.info "Team #{self.id}: " +
      "space taken: " +
      "#{orig_space}B + #{space}B = " +
      "#{self.space_taken}B (#{number_to_human_size(self.space_taken)})"
  end

  # Release specified amount of bytes
  def release_space(space)
    orig_space = self.space_taken
    self.space_taken = [space_taken - space,
                        Constants::MINIMAL_TEAM_SPACE_TAKEN].max
    Rails::logger.info "Team #{self.id}: " +
      "space released: " +
      "#{orig_space}B - #{space}B = " +
      "#{self.space_taken}B (#{number_to_human_size(self.space_taken)})"
  end

  def protocol_keywords_list
    ProtocolKeyword.where(team: self).pluck(:name)
  end
end
