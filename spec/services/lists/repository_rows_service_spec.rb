# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lists::RepositoryRowsService do
  
  before(:all) do
    team = create(:team)
    user = create(:user)
    repository = create(:repository, created_by: user)
    text_column = create(:repository_column, :text_type, repository: repository, created_by: user)

    10.times do
      repository_rows = build_list(:repository_row, 10, repository: repository, created_by: repository.created_by, last_modified_by: repository.created_by)
      result = RepositoryRow.import(repository_rows, validate: false)
      repository_rows = RepositoryRow.where(id: result.ids)
      repository_text_values = []
      repository_rows.each do |repository_row|
        repository_text_values << build(:repository_text_value, data: Faker::Name.name, created_by: user, repository_cell_attributes: { repository_row: repository_row, repository_column: text_column })
      end
      RepositoryTextValue.import(repository_text_values, recursive: true, validate: false)
    end
  end

  let!(:repository) { Repository.take }
  let!(:text_column) { repository.repository_columns.find_by(data_type: 'RepositoryTextValue') }
  let!(:user) { repository.created_by }
  let!(:repository_rows) { repository.repository_rows.active }
  let!(:archived_repository_rows) { repository.repository_rows.archived }
  let(:params) {{ page: 1, per_page: 10, search: '' } }
  let(:service) { described_class.new(repository, params, user: user) }

  describe '#call' do
    context 'when view_mode is archived' do
      it 'fetches only archived repository_rows' do
        params[:archived] = 'true'
        repository_rows.limit(10).update_all(archived: true)

        expect(service.call).to all(be_archived)
      end
    end

    context 'when view_mode is active' do
      it 'fetches only active repository_rows' do
        expect(service.call).to all(be_active)
      end

      it 'fetches only active repository_rows within specified time' do
        times = 5.times.map { Benchmark.realtime { service.call } }
        expect(times.min).to be < 0.01
      end
    end

    context 'when ordering param is present' do
      it 'is ordered by row name asc' do
        params[:order] = { column: 'repository_rows.name', dir: 'asc' }
        repository_rows.second.update_column(:name, '0')
        repository_rows = service.call

        expect(repository_rows.first.name).to eq('0')
      end

      it 'is ordered by row name desc' do
        params[:order] = { column: 'repository_rows.name', dir: 'desc' }
        repository_rows.second.update_column(:name, 'ZZZZZ')
        repository_rows = service.call

        expect(repository_rows.first.name).to eq('ZZZZZ')
      end
    end

    context 'when search param is present' do
      it 'filters repository_rows by search param and row name' do
        params[:search] = 'search-item-test'
        repository_rows.second.update_column(:name, 'search-item-test 1')
        repository_rows.third.update_column(:name, 'search-item-test 2')

        service.call.each do |record|
          expect(record.name).to include('search-item-test')
        end
      end

      it 'filters repository_rows by search param and text cell value' do
        params[:search] = 'search-item-test'
        repository_rows.second.repository_text_values.first.update_column(:data, 'search-item-test 1')
        repository_rows.third.repository_text_values.first.update_column(:data, 'search-item-test 2')

        service.call.each do |record|
          expect(record.repository_text_values.first.data).to include('search-item-test')
        end
      end
    end

    context 'when text advanced filter is present' do
      it 'filters repository_rows by row id containing search query' do
        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: 'row_id',
            operator: 'contains',
            parameters: { text: '1' }
          ]
        }

        service.call.each do |record|
          expect(record.name).to include('1')
        end
      end

      it 'filters repository_rows by row id not containing search query' do
        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: 'row_id',
            operator: 'doesnt_contain',
            parameters: { text: '1' }
          ]
        }

        service.call.each do |record|
          expect(record.name).not_to include('1')
        end
      end

      it 'filters repository_rows by row name containing search query' do
        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: 'row_name',
            operator: 'contains',
            parameters: { text: 'search-item-test' }
          ]
        }

        repository_rows.second.update_column(:name, 'search-item-test 1')
        repository_rows.third.update_column(:name, 'search-item-test 2')

        service.call.each do |record|
          expect(record.name).to include('search-item-test')
        end
      end

      it 'filters repository_rows by row name not containing search query' do
        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: 'row_name',
            operator: 'doesnt_contain',
            parameters: { text: 'search-item-test' }
          ]
        }

        repository_rows.second.update_column(:name, 'search-item-test 1')
        repository_rows.third.update_column(:name, 'search-item-test 2')

        service.call.each do |record|
          expect(record.name).not_to include('search-item-test')
        end
      end
    end

    context 'when added_on advanced filter is present' do
      it 'filters repository_rows created after the specified date' do
        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: 'added_on',
            operator: 'greater_than',
            parameters: { datetime: 1.day.ago.to_s }
          ]
        }

        repository_rows.second.update_column(:created_at, 2.days.ago)
        repository_rows.third.update_column(:created_at, 3.days.ago)

        expect(service.call.pluck(:created_at)).to all(be > 1.day.ago)
      end

      it 'filters repository_rows created during "today"' do
        params[:advanced_search] = {
          filter_elements: [
            { 
              repository_column_id: 'added_on', 
              operator: 'today'
            }
          ]
        }  

        expect(service.call.pluck(:created_at)).to all(be > DateTime.now.beginning_of_day && be < DateTime.now.end_of_day)
      end

      it 'filters repository_rows created during "yesterday"' do
        previous_day_repository_row = repository_rows.second
        previous_day_repository_row.update_column(:created_at, 1.day.ago)

        params[:advanced_search] = {
          filter_elements: [
            { 
              repository_column_id: 'added_on', 
              operator: 'yesterday'
            }
          ]
        }  

        repository_rows = service.call
        expect(repository_rows).to include(previous_day_repository_row)
        expect(repository_rows.pluck(:created_at)).to all(be > 1.day.ago.beginning_of_day && be < 1.day.ago.end_of_day)
      end

      it 'filters repository_rows created during "last_week"' do
        previous_week_repository_row = repository_rows.second
        previous_week_repository_row.update_column(:created_at, 1.week.ago)

        params[:advanced_search] = {
          filter_elements: [
            { 
              repository_column_id: 'added_on', 
              operator: 'last_week'
            }
          ]
        }  

        repository_rows = service.call
        expect(repository_rows).to include(previous_week_repository_row)
        expect(repository_rows.pluck(:created_at)).to all(be > 1.week.ago.beginning_of_week && be < 1.week.ago.end_of_week)
      end
      

      it 'filters repository_rows created during "this_month"' do
        previous_month_repository_row = repository_rows.second
        previous_month_repository_row.update_column(:created_at, 1.month.ago)

        params[:advanced_search] = {
          filter_elements: [
            { 
              repository_column_id: 'added_on', 
              operator: 'this_month'
            }
          ]
        }  

        repository_rows = service.call
        expect(repository_rows).not_to include(previous_month_repository_row)
        expect(repository_rows.pluck(:created_at)).to all(be > DateTime.now.beginning_of_month && be < DateTime.now.end_of_month)
      end

      it 'filters repository_rows created during "last_year"' do
        last_year_repository_row = repository_rows.second
        last_year_repository_row.update_column(:created_at, 1.year.ago.end_of_year)

        params[:advanced_search] = {
          filter_elements: [
            { 
              repository_column_id: 'added_on', 
              operator: 'last_year'
            }
          ]
        }  

        repository_rows = service.call
        expect(repository_rows).to include(last_year_repository_row)
        expect(repository_rows.pluck(:created_at)).to all(be < 1.year.ago.end_of_year)
      end

      it 'filters repository_rows created during "this_year"' do
        last_year_repository_row = repository_rows.second
        last_year_repository_row.update_column(:created_at, 1.year.ago.end_of_year)

        params[:advanced_search] = {
          filter_elements: [
            { 
              repository_column_id: 'added_on', 
              operator: 'this_year'
            }
          ]
        }  

        repository_rows = service.call
        expect(repository_rows).to_not include(last_year_repository_row)
        expect(repository_rows.pluck(:created_at)).to all(be > 1.year.ago.end_of_year && be < 1.year.after.beginning_of_year)
      end

      it 'filters repository_rows created between the specified dates' do
        params[:advanced_search] = {
          filter_elements: [
            repository_column_id: 'added_on',
            operator: 'between',
            parameters: { start_datetime: 5.days.ago.to_s, end_datetime: 5.days.after.to_s }
          ]
        }

        repository_rows.second.update_column(:created_at, 20.days.after)
        repository_rows.third.update_column(:created_at, 33.days.ago)

        expect(service.call.pluck(:created_at)).to all(be > 5.days.ago && be < 5.days.after)
      end
    end

    context 'when added_by advanced filter is present' do
      it 'filters repository_rows created by specified user' do
        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: 'added_by',
            operator: 'any_of',
            parameters: { user_ids: [ user.id ] }
          ]
        }

        expect(service.call.pluck(:created_by_id)).to all(be user.id)
      end

      it 'filters repository_rows not created by specified user' do
        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: 'added_by',
            operator: 'none_of',
            parameters: { user_ids: [ user.id ] }
          ]
        }

        expect(service.call).to be_empty
      end
    end

    context 'when custom text column advanced filter is present' do
      it 'filters repository_rows by specified text value' do
        second_row = repository_rows.second
        third_row = repository_rows.third
        second_row.repository_text_values.take.update_column(:data, 'search-item-test 1')
        third_row.repository_text_values.take.update_column(:data, 'search-item-test 2')

        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: text_column.id,
            operator: 'contains',
            parameters: { text: 'search-item-test' }
          ]
        }

        expect(service.call.pluck(:id)).to match([second_row.id, third_row.id])
      end

      it 'filters repository_rows by not containing specified text value' do
        second_row = repository_rows.second
        third_row = repository_rows.third
        second_row.repository_text_values.take.update_column(:data, 'search-item-test 1')
        third_row.repository_text_values.take.update_column(:data, 'search-item-test 2')

        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: text_column.id,
            operator: 'doesnt_contain',
            parameters: { text: 'search-item-test' }
          ]
        }

        expect(service.call.pluck(:id)).not_to include([second_row.id, third_row.id])
      end
    end
  end
end
