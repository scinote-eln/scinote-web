# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::Service::ProtocolsController", type: :request do
  before :all do
    @user = create(:user)
    @team = create(:team, :change_user_team, created_by: @user)

    @project = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team)
    @experiment = create(:experiment, created_by: @user, last_modified_by: @user, project: @project, created_by: @user)
    @my_module = create(
      :my_module,
      :with_due_date,
      created_by: @user,
      last_modified_by: @user,
      experiment: @experiment
    )

    @protocol = create(:protocol, team: @team, my_module: @my_module, name: "Test protocol")

    create_list(:step, 3, protocol: @protocol)

    @valid_headers =
      {
        'Authorization'=> 'Bearer ' + generate_token(@user.id),
        'Content-Type' => 'application/json'
      }
  end

  describe 'POST reorder steps, #reorder_steps' do
    let(:action) do
      post(
        api_service_team_protocol_reorder_steps_path(
          team_id: @team.id,
          protocol_id: @protocol.id
        ),
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      let(:request_body) do
        { step_order:
            @protocol.steps.pluck(:id).each_with_index.map do |id, i|
              { id: id, position: @protocol.steps.length - 1 - i }
            end
        }
      end

      it 'returns status 200 and reorderes steps' do
        action
        expect(response).to have_http_status 200

        new_step_order = @protocol.steps.order(position: :asc).pluck(:id, :position)

        expect(new_step_order).to(
          eq(
            request_body[:step_order].map(&:values).sort { |a, b| a[1] <=> b[1] }
          )
        )
      end
    end

    context "when step order doesn't include all step ids" do
      let(:request_body) do
        { step_order:
            @protocol.steps.last(2).pluck(:id).each_with_index.map do |id, i|
              { id: id, position: @protocol.steps.length - 1 - i }
            end
        }
      end

      it 'returns status 400' do
        action
        expect(response).to have_http_status 400
      end
    end

    context "when step order doesn't have the correct positions" do
      let(:request_body) do
        { step_order:
            @protocol.steps.last(2).pluck(:id).each_with_index.map do |id, i|
              { id: id, position: i + 1 }
            end
        }
      end

      it 'returns status 400' do
        action
        expect(response).to have_http_status 400
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {}
      end

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end
    end
  end
end
