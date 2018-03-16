require 'rails_helper'

describe 'samples_to_repository_migration:run' do
  include_context 'rake'
  let!(:user) { create :user, email: 'happy.user@scinote.net' }
  let!(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, user: user, team: team }
  let!(:my_module) { create :my_module }
  let(:sample_types_names) { %w(type_one type_two type_three) }
  let(:sample_group_names) { %w(group_one group_two group_three) }

  before do
    sample_types = []
    sample_types_names.each do |name|
      sample_type = create :sample_type, name: name, team: team
      sample_types << sample_type
    end
    sample_groups = []
    sample_group_names.each do |name|
      sample_group = create :sample_group, name: name, team: team
      sample_groups << sample_group
    end
    custom_field = create :custom_field, name: 'Banana', team: team, user: user
    100.times do |index|
      sample = create :sample, name: "Sample (#{index})", user: user, team: team
      create :sample_my_module, sample: sample, my_module: my_module
      sample.sample_type = sample_types[rand(0...2)]
      sample.sample_group = sample_groups[rand(0...2)]
      custom_value = create :sample_custom_field,
                            value: "custom value (#{index})",
                            custom_field: custom_field,
                            sample: sample
      sample.sample_custom_fields << custom_value
      sample.save
    end
  end

  it 'generates a new custom repository with exact copy of samples' do
    subject.invoke
    expect(Repository.first.name).to eq 'Samples'
    expect(RepositoryRow.count).to eq 100
    RepositoryRow.all.each do |row|
      row_my_module = MyModuleRepositoryRow.where(repository_row: row,
                                                  my_module: my_module)
      expect(row_my_module).to exist
      expect(row.name).to match(/Sample \([0-9]*\)/)
      expect(row.created_by).to eq user

      # repository sample_type column
      sample_type_column = row.repository_cells.first
      expect(sample_types_names).to include(sample_type_column.value.formatted)
      expect(sample_type_column.repository_column.name).to eq 'Sample type'
      expect(sample_type_column.value_type).to eq 'RepositoryListValue'

      # repository sample_group column
      sample_group_column = row.repository_cells.second
      expect(sample_group_names).to include(sample_group_column.value.formatted)
      expect(sample_group_column.repository_column.name).to eq 'Sample group'
      expect(sample_group_column.value_type).to eq 'RepositoryListValue'

      # repository color column
      color_column = row.repository_cells.third
      expect(
        color_column.repository_column.name
      ).to eq 'Sample group color hex'
      expect(color_column.value_type).to eq 'RepositoryTextValue'

      # repository custom column
      custom_column = row.repository_cells.last
      expect(custom_column.value.formatted).to match(/custom value \([0-9]*\)/)
      expect(custom_column.repository_column.name).to eq 'Banana'
      expect(custom_column.value_type).to eq 'RepositoryTextValue'
    end
  end
end
