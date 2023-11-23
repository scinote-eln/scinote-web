# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::Service::StepsController", type: :request do
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
    @step = create(:step, protocol: @protocol)

    create_list(:step_orderable_element, 3, step: @step)

    @valid_headers =
      {
        'Authorization'=> 'Bearer ' + generate_token(@user.id),
        'Content-Type' => 'application/json'
      }
  end

  describe 'POST reorder steps, #reorder_steps' do
    let(:action) do
      post(
        api_service_team_step_reorder_elements_path(
          team_id: @team.id,
          step_id: @step.id
        ),
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      let(:request_body) do
        { step_element_order:
            @step.step_orderable_elements.pluck(:id).each_with_index.map do |id, i|
              { id: id, position: @step.step_orderable_elements.length - 1 - i }
            end
        }
      end

      it 'returns status 200 and reorderes step elements' do
        action

        expect(response).to have_http_status 200
        new_step_element_order = @step.step_orderable_elements.order(position: :asc).pluck(:id, :position)

        expect(new_step_element_order).to(
          eq(
            request_body[:step_element_order].map(&:values).sort { |a, b| a[1] <=> b[1] }
          )
        )
      end
    end

    context "when step order doesn't include all step ids" do
      let(:request_body) do
        { step_element_order:
          @step.step_orderable_elements.last(2).pluck(:id).each_with_index.map do |id, i|
              { id: id, position: @step.step_orderable_elements.length - 1 - i }
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
        { step_element_order:
            @step.step_orderable_elements.last(2).pluck(:id).each_with_index.map do |id, i|
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
