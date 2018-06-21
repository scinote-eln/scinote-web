require 'rails_helper'

describe RepositoryImportParser::RepositoryCellValueResolver do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:user_team) { create :user_team, user: user, team: team }
  let(:repository) { create :repository, team: team, created_by: user }
  let!(:sample_group_column) do
    create :repository_column, repository: repository,
                               created_by: user,
                               name: 'Sample group',
                               data_type: 'RepositoryListValue'
  end
  let!(:custom_column) do
    create :repository_column, repository: repository,
                               created_by: user,
                               name: 'Custom items',
                               data_type: 'RepositoryTextValue'
  end

  let!(:repository_row) do
    create :repository_row, repository: repository,
                            created_by: user,
                            name: 'Sample'
  end

  describe '#ruget_valuen/2' do
    context 'RepositoryListValue' do
      let(:subject) do
        RepositoryImportParser::RepositoryCellValueResolver.new(
          sample_group_column, user, repository, 0
        )
      end

      it 'returns a valid RepositoryListValue object' do
        value = subject.get_value('leaf', repository_row)
        expect(value).to be_valid
        expect(value).to be_a RepositoryListValue
        expect(value.formatted).to eq 'leaf'
      end

      it 'creates a new RepositoryListItem' do
        value = subject.get_value('leaf', repository_row)
        item = sample_group_column.repository_list_items.find_by_data('leaf')
        expect(sample_group_column.repository_list_items.count).to eq 1
        expect(item).to be_present
        expect(item.data).to eq 'leaf'
      end
    end

    context 'RepositoryTextValue' do
      let(:subject) do
        RepositoryImportParser::RepositoryCellValueResolver.new(
          custom_column, user, repository, 0
        )

        it 'returns a valid RepositoryTextValue object' do
          value = subject.get_value('blood', repository_row)
          expect(value).to be_valid
          expect(value).to be_a RepositoryTextValue
          expect(value.formatted).to eq 'blood'
        end
      end
    end
  end
end
