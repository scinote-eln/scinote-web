require 'rails_helper'

describe ProjectsJsonExportService do
  before :all do
    @user = create(:user)
    @team = create(:team, :change_user_team, created_by: @user)

    @accessible_project_1 = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team)
    @accessible_project_2 = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team)
    @unaccessible_project = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team)
    @accessible_experiment_1 = create(:experiment, created_by: @user,
                                      last_modified_by: @user, project: @accessible_project_1)
    @accessible_experiment_2 = create(:experiment, created_by: @user,
                                      last_modified_by: @user, project: @accessible_project_2)
    @unaccessible_experiment = create(:experiment, created_by: @user,
                                      last_modified_by: @user, project: @unaccessible_project)
    @accessible_task_1 = create(:my_module, :with_due_date, created_by: @user,
                                last_modified_by: @user, experiment: @accessible_experiment_1)
    @accessible_task_2 = create(:my_module, :with_due_date, created_by: @user,
                                last_modified_by: @user, experiment: @accessible_experiment_2)

    @unaccessible_task = create(:my_module, :with_due_date, created_by: @user,
                                last_modified_by: @user, experiment: @unaccessible_experiment)
    
    
    @unaccessible_project.user_assignments.destroy_all
  end

  describe 'Generate project json' do
    let(:action) do
      ProjectsJsonExportService.new(task_ids, Faker::Internet.url, @user).generate_data
    end

    let(:one_project) do
      [@accessible_task_1.id]
    end

    let(:multiple_projects) do
      [@accessible_task_1.id, @accessible_task_2.id, @unaccessible_task.id]
    end

    let(:no_accessible_projects) do
      [@unaccessible_task.id]
    end

    context 'One project' do
      let(:task_ids) do
        one_project
      end
      it 'Get response one project' do
        response = action
        expect(response.length).to eq 1
        expect(response[0].keys).to contain_exactly('id', 'name', 'experiments')
        expect(response[0]['experiments'].length).to eq 1
        expect(response[0]['experiments'][0].keys).to contain_exactly('id', 'name', 'description', 'tasks')
        expect(response[0]['experiments'][0]['tasks'].length).to eq 1
      end
    end

    context 'Multiple projects' do
      let(:task_ids) do
        multiple_projects
      end
      it 'Get response multiple projects' do
        response = action
        expect(response.length).to eq 2
        expect(response[0].keys).to contain_exactly('id', 'name', 'experiments')
        expect(response[0]['experiments'].length).to eq 1
        expect(response[0]['experiments'][0].keys).to contain_exactly('id', 'name', 'description', 'tasks')
        expect(response[0]['experiments'][0]['tasks'].length).to eq 1
      end
    end

    context 'Not accessible project' do
      let(:task_ids) do
        no_accessible_projects
      end
      it 'Get response for not accessible project' do
        response = action
        expect(response.length).to eq 0
      end
    end

  end

end
