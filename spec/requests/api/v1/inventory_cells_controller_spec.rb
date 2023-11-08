# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::InventoryCellsController', type: :request do
  before :all do
    @user = create(:user)
    @another_user = create(:user)
    @team = create(:team, created_by: @user)
    @wrong_team = create(:team, created_by: @another_user)

    # valid_inventory
    @valid_inventory = create(:repository, name: Faker::Name.unique.name, created_by: @user, team: @team)

    # unaccessable_inventory
    @wrong_inventory = create(:repository, name: Faker::Name.unique.name, created_by: @another_user, team: @wrong_team)

    create(:repository_row, repository: @wrong_inventory)

    @text_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryTextValue)
    @list_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryListValue)
    list_item = create(:repository_list_item, repository_column: @list_column, data: Faker::Name.unique.name)
    second_list_item = create(:repository_list_item, repository_column: @list_column, data: Faker::Name.unique.name)
    @status_column = create(:repository_column, repository: @valid_inventory, data_type: :RepositoryStatusValue)
    status_item = create(:repository_status_item, repository_column: @status_column)
    second_status_item = create(:repository_status_item, repository_column: @status_column)
    @checklist_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryChecklistValue)
    checklist_items = create_list(:repository_checklist_item, 3, repository_column: @checklist_column)
    checklist_item =
      create(:repository_checklist_item, repository_column: @checklist_column, data: Faker::Name.unique.name)
    @file_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryAssetValue)
    asset = create(:asset)
    @date_column = create(:repository_column, repository: @valid_inventory, data_type: :RepositoryDateValue)
    @time_column = create(:repository_column, repository: @valid_inventory, data_type: :RepositoryTimeValue)
    @date_time_column = create(:repository_column, repository: @valid_inventory, data_type: :RepositoryDateTimeValue)
    @date_range_column = create(:repository_column, repository: @valid_inventory, data_type: :RepositoryDateRangeValue)
    @time_range_column = create(:repository_column, repository: @valid_inventory, data_type: :RepositoryTimeRangeValue)
    @date_time_range_column = create(:repository_column,
                                     repository: @valid_inventory, data_type: :RepositoryDateTimeRangeValue)
    @number_column = create(:repository_column, repository: @valid_inventory, data_type: :RepositoryNumberValue)
    @stock_column = create(:repository_column, name: Faker::Name.unique.name,
                           data_type: :RepositoryStockValue, repository: @valid_inventory)
    @repository_stock_unit_item = create( :repository_stock_unit_item, created_by: @user,
                                                                       last_modified_by: @user,
                                                                       repository_column: @stock_column)

    @valid_item = create(:repository_row, repository: @valid_inventory)

    create(:repository_text_value,
           data: Faker::Name.name,
           repository_cell_attributes: { repository_row: @valid_item, repository_column: @text_column })
    create(:repository_list_value, repository_list_item: list_item,
           repository_cell_attributes: { repository_row: @valid_item, repository_column: @list_column })
    create(:repository_status_value, repository_status_item: status_item,
           repository_cell_attributes: { repository_row: @valid_item, repository_column: @status_column })
    create(:repository_checklist_value, repository_checklist_items: checklist_items,
           repository_cell_attributes: { repository_row: @valid_item, repository_column: @checklist_column })
    create(:repository_asset_value, asset: asset,
           repository_cell_attributes: { repository_row: @valid_item, repository_column: @file_column })
    create(:repository_date_value,
           data: Time.zone.today,
           repository_cell_attributes: { repository_row: @valid_item, repository_column: @date_column })
    create(:repository_time_value,
           data: Time.zone.now,
           repository_cell_attributes: { repository_row: @valid_item, repository_column: @time_column })
    create(:repository_date_time_value,
           data: DateTime.now,
           repository_cell_attributes: { repository_row: @valid_item, repository_column: @date_time_column })
    create(:repository_date_range_value,
           start_time: Time.zone.today,
           end_time: Time.zone.today + 1.day,
           repository_cell_attributes: { repository_row: @valid_item, repository_column: @date_range_column })
    create(:repository_time_range_value,
           start_time: Time.zone.now,
           end_time: Time.zone.now + 1.hour,
           repository_cell_attributes: { repository_row: @valid_item, repository_column: @time_range_column })
    create(:repository_date_time_range_value,
           start_time: DateTime.now,
           end_time: DateTime.now + 1.day,
           repository_cell_attributes: { repository_row: @valid_item, repository_column: @date_time_range_column })
    create(:repository_number_value,
           data: 1234.5678,
           repository_cell_attributes: { repository_row: @valid_item, repository_column: @number_column })
    create(:repository_stock_value,
           amount: 10,
           repository_stock_unit_item: @repository_stock_unit_item,
           repository_cell_attributes: { repository_row: @valid_item, repository_column: @stock_column })

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id),
        'Content-Type': 'application/json' }

    @valid_text_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @text_column.id,
          value: Faker::Name.unique.name
        }
      }
    }
    @valid_list_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @list_column.id,
          value: list_item.id
        }
      }
    }
    @valid_status_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @status_column.id,
          value: status_item.id
        }
      }
    }
    @valid_checklist_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @checklist_column.id,
          value: checklist_items.pluck(:id)
        }
      }
    }
    @valid_file_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @file_column.id,
          value: {
            file_name: 'test.txt',
            file_data: 'data:text/plain;base64,dGVzdAo='
          }
        }
      }
    }
    @valid_date_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @date_column.id,
          value: Time.zone.today
        }
      }
    }
    @valid_time_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @time_column.id,
          value: Time.zone.now
        }
      }
    }
    @valid_date_time_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @date_time_column.id,
          value: DateTime.now
        }
      }
    }
    @valid_date_range_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @date_range_column.id,
          value: {
            start_time: Time.zone.today,
            end_time: Time.zone.today + 1.day
          }
        }
      }
    }
    @valid_time_range_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @time_range_column.id,
          value: {
            start_time: Time.zone.now,
            end_time: Time.zone.now + 1.hour
          }
        }
      }
    }
    @valid_date_time_range_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @date_time_range_column.id,
          value: {
            start_time: DateTime.now,
            end_time: DateTime.now + 1.day
          }
        }
      }
    }
    @valid_number_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @number_column.id,
          value: 1234.5678
        }
      }
    }
    @valid_number_as_text_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @number_column.id,
          value: '1234.5678'
        }
      }
    }
    @valid_stock_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @stock_column.id,
          value: {
            amount: 19,
            unit_item_id: @repository_stock_unit_item.id
          }
        }
      }
    }
    @update_text_body = {
      data: {
        id: @valid_item.repository_cells.where(repository_column: @text_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @text_column.id,
          value: Faker::Name.unique.name
        }
      }
    }
    @update_list_body = {
      data: {
        id: @valid_item.repository_cells.where(repository_column: @list_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @list_column.id,
          value: second_list_item.id
        }
      }
    }
    @update_status_body = {
      data: {
        id: @valid_item.repository_cells.where(repository_column: @status_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @status_column.id,
          value: second_status_item.id
        }
      }
    }
    @update_checklist_body = {
      data: {
        id: @valid_item.repository_cells.where(repository_column: @checklist_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @list_column.id,
          value: [checklist_item.id]
        }
      }
    }
    @update_file_body = {
      data: {
        id: @valid_item.repository_cells.where(repository_column: @file_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @file_column.id,
          value: {
            file_name: 'test.txt',
            file_data: 'data:text/plain;base64,dGVzdDIK='
          }
        }
      }
    }
    @update_date_body = {
      data: {
        id: @valid_item.repository_cells.where(repository_column: @date_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @date_column.id,
          value: Time.zone.today + 2.days
        }
      }
    }
    @update_time_body = {
      data: {
        id: @valid_item.repository_cells.where(repository_column: @time_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @time_column.id,
          value: Time.zone.now + 2.hours
        }
      }
    }
    @update_date_time_body = {
      data: {
        id: @valid_item.repository_cells.where(repository_column: @date_time_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @date_time_column.id,
          value: DateTime.now + 2.hours
        }
      }
    }
    @update_date_range_body = {
      data: {
        id: @valid_item.repository_cells.where(repository_column: @date_range_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @date_range_column.id,
          value: {
            start_time: Time.zone.today,
            end_time: Time.zone.today + 2.days
          }
        }
      }
    }
    @update_time_range_body = {
      data: {
        id: @valid_item.repository_cells.where(repository_column: @time_range_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @time_range_column.id,
          value: {
            start_time: Time.zone.now,
            end_time: Time.zone.now + 2.hours
          }
        }
      }
    }
    @update_date_time_range_body = {
      data: {
        id: @valid_item.repository_cells.where(repository_column: @date_time_range_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @date_time_range_column.id,
          value: {
            start_time: DateTime.now,
            end_time: DateTime.now + 2.hours
          }
        }
      }
    }
    @update_number_body = {
      data: {
        id: @valid_item.repository_cells.where(repository_column: @number_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @number_column.id,
          value: 8765.4321
        }
      }
    }
    @update_number_as_text_body = {
      data: {
        id: @valid_item.repository_cells.where(repository_column: @number_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @number_column.id,
          value: '8765.4321'
        }
      }
    }
    @update_stock_body = {
      data: {
        id: @valid_item.repository_cells.where(repository_column: @stock_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @stock_column.id,
          value: {
            amount: 20,
            unit_item_id: @repository_stock_unit_item.id
          }
        }
      }
    }
  end

  describe 'GET inventory_cells, #index' do
    it 'Response with correct inventory cells' do
      hash_body = nil
      get api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        page: { size: 100 }
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells, each_serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_inventory_item_cells_path(
        team_id: @wrong_team.id,
        inventory_id: @wrong_inventory.id,
        item_id: 999
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing item' do
      hash_body = nil
      get api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory,
        item_id: 999
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET inventory_cells, #show' do
    it 'Response with correct inventory cell' do
      hash_body = nil
      get api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells.first, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_inventory_item_cell_path(
        team_id: @wrong_team.id,
        inventory_id: @wrong_inventory.id,
        item_id: 999,
        id: 999
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing cell' do
      hash_body = nil
      get api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory,
        item_id: @valid_item,
        id: 999
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'POST inventory_cells, #create' do
    it 'Response with correct inventory cell, text cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryCell.last, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, list cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_list_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryCell.last, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, status cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_status_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryCell.last, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, checklist cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_checklist_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryCell.last, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, file cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_file_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryCell.last, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, date cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_date_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryCell.last, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, time cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_time_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryCell.last, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, date_time cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_date_time_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryCell.last, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, date_range cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_date_range_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryCell.last, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, time_range cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_time_range_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryCell.last, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, date_time_range cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_date_time_range_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryCell.last, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, number cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_number_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryCell.last, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, text number cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_number_as_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryCell.last, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, stock cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_stock_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryCell.last, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with inventory cell, stock cell, empty stock unit' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      invalid_file_body = @valid_stock_body.deep_dup
      invalid_file_body[:data][:attributes][:value].delete(:unit_item_id)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: invalid_file_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryCell.last, serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with inventory cell, stock cell, missing amount' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      invalid_file_body = @valid_stock_body.deep_dup
      invalid_file_body[:data][:attributes][:value].delete(:amount)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: invalid_file_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 400
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, payload mismatches column type' do
      hash_body = nil
      invalid_file_body = @valid_file_body.dup
      invalid_file_body[:data][:attributes][:value] = 'abc'
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: invalid_file_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 400
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, non existing inventory' do
      hash_body = nil
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: -1,
        item_id: @valid_item.id
      ), params: @valid_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      post api_v1_team_inventory_item_cells_path(
        team_id: @wrong_team.id,
        inventory_id: @wrong_inventory.id,
        item_id: 999
      ), params: @valid_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, repository from another team' do
      hash_body = nil
      post api_v1_team_inventory_items_path(
        team_id: @team.id,
        inventory_id: @wrong_inventory.id,
        item_id: -1
      ), params: @valid_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'PUT inventory_cells, #update' do
    it 'Response with correct inventory cell, text cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.where(repository_column: @text_column).first.id
      ), params: @update_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells.where(repository_column: @text_column).first,
                 serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, list cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.where(repository_column: @list_column).first.id
      ), params: @update_list_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells.where(repository_column: @list_column).first,
                 serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, status cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.where(repository_column: @status_column).first.id
      ), params: @update_status_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells.where(repository_column: @status_column).first,
                 serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, checklist cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells
                       .where(repository_column: @checklist_column).first.id
      ), params: @update_checklist_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells.where(repository_column: @checklist_column).first,
                 serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, file cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.where(repository_column: @file_column).first.id
      ), params: @update_file_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells.where(repository_column: @file_column).first,
                 serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, date cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.where(repository_column: @date_column).first.id
      ), params: @update_date_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells.where(repository_column: @date_column).first,
                 serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, time cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.where(repository_column: @time_column).first.id
      ), params: @update_time_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells.where(repository_column: @time_column).first,
                 serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, date_time cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.where(repository_column: @date_time_column).first.id
      ), params: @update_date_time_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells.where(repository_column: @date_time_column).first,
                 serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, date_range cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.where(repository_column: @date_range_column).first.id
      ), params: @update_date_range_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells.where(repository_column: @date_range_column).first,
                 serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, time_range cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.where(repository_column: @time_range_column).first.id
      ), params: @update_time_range_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells.where(repository_column: @time_range_column).first,
                 serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, date_time_range cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.where(repository_column: @date_time_range_column).first.id
      ), params: @update_date_time_range_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells.where(repository_column: @date_time_range_column).first,
                 serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, number cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.where(repository_column: @number_column).first.id
      ), params: @update_number_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells.where(repository_column: @number_column).first,
                 serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, text number cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.where(repository_column: @number_column).first.id
      ), params: @update_number_as_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells.where(repository_column: @number_column).first,
                 serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct inventory cell, stock cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.where(repository_column: @stock_column).first.id
      ), params: @update_stock_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_item.repository_cells.where(repository_column: @stock_column).first,
                 serializer: Api::V1::InventoryCellSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, payload mismatches column type' do
      hash_body = nil
      invalid_file_body = @valid_file_body.dup
      invalid_file_body[:data][:attributes][:value] = 'abc'
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.where(repository_column: @file_column).first.id
      ), params: invalid_file_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 400
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, non existing inventory' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: -1,
        item_id: @valid_item.id,
        id: -1
      ), params: @valid_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @wrong_team.id,
        inventory_id: @wrong_inventory.id,
        item_id: -1,
        id: -1
      ), params: @valid_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, repository from another team' do
      hash_body = nil
      patch api_v1_team_inventory_item_path(
        team_id: @team.id,
        inventory_id: @wrong_inventory.id,
        item_id: -1,
        id: -1
      ), params: @valid_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'DELETE inventory_cells, #destroy' do
    it 'Destroys inventory cell' do
      deleted_id = @valid_item.repository_cells.where(repository_column: @number_column).first.id
      delete api_v1_team_inventory_item_cell_path(
        id: deleted_id,
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id
      ), headers: @valid_headers
      expect(response).to have_http_status(200)
      expect(RepositoryCell.where(id: deleted_id)).to_not exist
    end

    it 'Destroys stock inventory cell' do
      deleted_id = @valid_item.repository_cells.where(repository_column: @stock_column).first.id
      delete api_v1_team_inventory_item_cell_path(
        id: deleted_id,
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id
      ), headers: @valid_headers
      expect(response).to have_http_status(200)
      expect(RepositoryCell.where(id: deleted_id)).to_not exist
    end

    it 'Invalid request, non existing inventory item' do
      deleted_id = RepositoryCell.last.id + 1
      delete api_v1_team_inventory_item_cell_path(
        id: deleted_id,
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
    end
  end
end
