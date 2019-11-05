# frozen_string_literal: true

require 'rails_helper'

describe Tasks::SamplesToRepositoryMigrationService do
  let(:user) { create :user, email: 'happy.user@scinote.net' }
  let(:team) { create :team, created_by: user }
  let(:user_team) { create :user_team, user: user, team: team }

  describe '#prepare_repository/2' do
    context 'creates and return a new custom repository named' do
      it '"Samples" for team' do
        repository = Tasks::SamplesToRepositoryMigrationService
                     .prepare_repository(team)
        expect(repository).to be_an_instance_of(Repository)
        expect(repository.team).to eq team
        expect(repository.name).to eq 'Samples'
      end

      it '"Samples (1)" if repository name "Samples" already exists' do
        create :repository, name: 'Samples', team: team, created_by: user
        repository = Tasks::SamplesToRepositoryMigrationService
                     .prepare_repository(team)
        expect(repository).to be_an_instance_of(Repository)
        expect(repository.team).to eq team
        expect(repository.name).to eq 'Samples (1)'
      end
    end
  end

  describe '#prepare_text_value_custom_columns/2' do
    let(:repository) do
      create :repository, name: 'Samples', team: team, created_by: user
    end
    let(:subject) do
      Tasks::SamplesToRepositoryMigrationService
        .prepare_text_value_custom_columns(team, repository)
    end

    context 'custom columns exists' do
      before do
        create :samples_table, user: user, team: team
        10.times do |index|
          create :custom_field, name: "My Custom field (#{index})",
                                user: user,
                                team: team,
                                last_modified_by: user
        end
      end

      it { is_expected.to be_an Array }
      it { expect(subject.length).to eq 10 }
      it { expect(subject.first.name).to eq 'My Custom field (0)' }
      it { expect(subject.last.name).to eq 'My Custom field (9)' }
      it { expect(subject.first).to be_an_instance_of RepositoryColumn }
      it { expect(subject.first.data_type).to eq 'RepositoryTextValue' }
      it { expect(subject.first.repository).to eq repository }
    end

    context 'custom columns does not exists' do
      it { is_expected.to be_an Array }
      it { is_expected.to be_empty }
    end
  end

  describe '#prepare_list_value_custom_columns_with_list_items/2' do
    let(:repository) do
      create :repository, name: 'Samples', team: team, created_by: user
    end
    let(:subject) do
      Tasks::SamplesToRepositoryMigrationService
        .prepare_list_value_custom_columns_with_list_items(team, repository)
    end

    context 'with samples types' do
      before do
        10.times do |index|
          create :sample_type, name: "Sample Type Item (#{index})",
                               team: team,
                               created_by: user,
                               last_modified_by: user
        end
      end

      it { is_expected.to be_an Array }
      it { expect(subject.length).to eq 3 }
      it { expect(subject.first).to be_an_instance_of(RepositoryColumn) }
      it { expect(subject.first.name).to eq 'Sample group' }
      it { expect(subject.first.data_type).to eq 'RepositoryListValue' }
      it { expect(subject.second.name).to eq 'Sample type' }
      it { expect(subject.second.data_type).to eq 'RepositoryListValue' }
      it { expect(subject.last.name).to eq 'Sample group color hex' }
      it { expect(subject.last.data_type).to eq 'RepositoryTextValue' }

      describe 'generated list items from sample types' do
        let!(:generated_list_items) { subject.second.repository_list_items }
        it { expect(generated_list_items.count).to eq 10 }

        it 'has generated list_items with similar properties' do
          generated_list_items.each_with_index do |item, index|
            expect(item.data).to eq "Sample Type Item (#{index})"
            expect(item).to be_an_instance_of RepositoryListItem
            expect(item.created_by).to eq user
            expect(item.last_modified_by).to eq user
          end
        end
      end

      describe 'sample type without created_at/last_modified_by field' do
        before do
          team.sample_types.update_all(created_by_id: nil,
                                       last_modified_by_id: nil)
        end

        it 'generates valid list_items' do
          generated_list_items = subject.second.repository_list_items.order(:id)
          expect(generated_list_items.count).to eq 10
          generated_list_items.each_with_index do |item, index|
            expect(item.data).to eq "Sample Type Item (#{index})"
            expect(item).to be_an_instance_of RepositoryListItem
            expect(item.created_by).to eq team.created_by
            expect(item.last_modified_by).to eq team.created_by
          end
        end
      end
    end

    context 'with samples groups' do
      before do
        10.times do |index|
          create :sample_group, name: "Sample Group Item (#{index})",
                                color: '#000000',
                                team: team,
                                created_by: user,
                                last_modified_by: user
        end
      end

      it { is_expected.to be_an Array }
      it { expect(subject.length).to eq 3 }
      it { expect(subject.first).to be_an_instance_of(RepositoryColumn) }
      it { expect(subject.last).to be_an_instance_of(RepositoryColumn) }
      it { expect(subject.first.name).to eq 'Sample group' }
      it { expect(subject.first.data_type).to eq 'RepositoryListValue' }
      it { expect(subject.second.name).to eq 'Sample type' }
      it { expect(subject.second.data_type).to eq 'RepositoryListValue' }
      it { expect(subject.last.name).to eq 'Sample group color hex' }
      it { expect(subject.last.data_type).to eq 'RepositoryTextValue' }

      describe 'generated list items from sample groups' do
        let!(:generated_list_items) { subject.first.repository_list_items }
        it { expect(generated_list_items.count).to eq 10 }

        it 'has generated list_items with similar properties' do
          generated_list_items.each_with_index do |item, index|
            expect(item.data).to eq "Sample Group Item (#{index})"
            expect(item).to be_an_instance_of RepositoryListItem
            expect(item.created_by).to eq user
            expect(item.last_modified_by).to eq user
          end
        end
      end

      describe 'sample group without created_at/last_modified_by field' do
        before do
          team.sample_groups.update_all(created_by_id: nil,
                                        last_modified_by_id: nil)
        end

        it 'generates valid list_items' do
          generated_list_items = subject.first.repository_list_items.order(:id)
          expect(generated_list_items.count).to eq 10
          generated_list_items.each_with_index do |item, index|
            expect(item.data).to eq "Sample Group Item (#{index})"
            expect(item).to be_an_instance_of RepositoryListItem
            expect(item.created_by).to eq team.created_by
            expect(item.last_modified_by).to eq team.created_by
          end
        end
      end
    end
  end

  describe '#get_sample_custom_fields/1' do
    let(:sample) { create :sample, name: 'My sample', user: user, team: team }
    let(:custom_field) do
      create :custom_field, name: 'My Custom column',
                            user: user,
                            team: team,
                            last_modified_by: user
    end

    let(:subject) do
      Tasks::SamplesToRepositoryMigrationService
        .get_sample_custom_fields(sample.id)
    end
    context 'sample has custom column assigned' do
      before do
        create :samples_table, user: user, team: team
        create :sample_custom_field, value: 'field value',
                                     custom_field: custom_field,
                                     sample: sample
      end

      it 'returns a hash of sample values' do
        element = subject.first
        is_expected.to be_an Array
        expect(subject.length).to eq 1
        expect(element.fetch('column_name_reference')).to eq 'My Custom column'
        expect(element.fetch('value')).to eq 'field value'
        expect(element.fetch('created_at')).to be_present
        expect(element.fetch('updated_at')).to be_present
      end
    end

    context 'sample does not have custom columns assigned' do
      it { is_expected.to be_an Array }
      it { is_expected.to be_empty }
    end
  end

  describe '#get_assigned_sample_module/1' do
    let(:sample) { create :sample, name: 'My sample', user: user, team: team }
    let(:my_module) { create :my_module }
    let(:subject) do
      Tasks::SamplesToRepositoryMigrationService
        .get_assigned_sample_module(sample.id)
    end

    context 'sample is assigned to one module' do
      let!(:sample_my_module) do
        create :sample_my_module, sample: sample,
                                  my_module: my_module,
                                  assigned_by: user
      end

      it { is_expected.to be_an Array }
      it { expect(subject.length).to eq 1 }
      it 'returnes assigned my_module data' do
        my_module_data = subject.first
        expect(
          my_module_data.fetch('my_module_id')
        ).to eq sample_my_module.my_module_id
        expect(
          my_module_data.fetch('assigned_by_id')
        ).to eq sample_my_module.assigned_by_id
      end
    end

    context 'sample is not assigned to module' do
      it { is_expected.to be_an Array }
      it { is_expected.to be_empty }
    end

    context 'sample is assigned to multiple modules' do
      before do
        @modules_ids = []
        10.times do |index|
          my_module = create :my_module, name: "My module (#{index})"
          @modules_ids << my_module.id
        end
        10.times do |index|
          create :sample_my_module,
                 sample: sample,
                 my_module_id: @modules_ids[index],
                 assigned_by: user
        end
      end

      it { is_expected.to be_an Array }
      it { expect(subject.length).to eq 10 }

      it 'is expected to return an array of samples_my_modules data' do
        subject.each do |element|
          expect(@modules_ids).to include(element.fetch('my_module_id').to_i)
          expect(element.fetch('assigned_by_id')).to eq user.id
        end
      end
    end
  end

  describe 'fetch_all_team_samples/1' do
    let(:subject) do
      Tasks::SamplesToRepositoryMigrationService.fetch_all_team_samples(team)
    end

    context 'team has samples' do
      before do
        100.times do |index|
          create :sample, name: "Sample (#{index})", user: user, team: team
        end
      end

      it { is_expected.to be_an Array }
      it { expect(subject.length).to eq 100 }

      it 'returns an array of all team samples' do
        subject.each_with_index do |element, index|
          expect(element.fetch('sample_name')). to eq "Sample (#{index})"
        end
      end
    end

    context 'team does not have samples' do
      it { is_expected.to be_an Array }
      it { is_expected.to be_empty }
    end
  end
end
