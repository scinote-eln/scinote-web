# frozen_string_literal: true

require 'rails_helper'

describe CanvasController do
  login_user
  include_context 'reference_project_structure', {
    skip_my_module: true
  }

  let(:experiment2) { create :experiment, project: project, created_by: project.created_by }

  # Idea of this "end to end" test is to put a lot "work" on method `@experiment.udpate_canvas` and controller actipn
  # update also. We've implemented some unit tests on `.update_canvas` itself, but behaviour is tightly coupled with
  # canvas_controller itself. This test should be helpful also for potentional refactoring. Welcome to extend it.

  describe 'POST update' do
    # What should happen:
    #   - Add new task n0
    #   - Add new task n1 and move it to Experiment2
    #   - Rename task task1, change position to 0, 20
    #   - Rename task task2 and archive task2
    #   - Add new task n2 on the place of existing task1, previous location
    #   - Archive task3 and create new one n4 on position of this one
    #   - Clone task task5
    #   - Clone task task6, rename task6

    # Setup environment for "big change" request
    # Tasks in DB



    let!(:task1) { create :my_module, x: 0, y: 1, experiment: experiment, created_by: experiment.created_by }
    let!(:task2) { create :my_module, x: 0, y: 2, experiment: experiment, created_by: experiment.created_by }
    let!(:task3) { create :my_module, x: 0, y: 3, experiment: experiment, created_by: experiment.created_by }
    let!(:task4) { create :my_module, x: 0, y: 4, experiment: experiment, created_by: experiment.created_by }
    let!(:task5) { create :my_module, x: 0, y: 5, experiment: experiment, created_by: experiment.created_by }
    let!(:task6) { create :my_module, x: 0, y: 6, experiment: experiment, created_by: experiment.created_by }
    let!(:task7) { create :my_module, x: 0, y: 7, experiment: experiment, created_by: experiment.created_by }
    let!(:task8) { create :my_module, x: 0, y: 8, experiment: experiment, created_by: experiment.created_by }

    let!(:step_on_task5) { create :step, name: 'task5_step', protocol: task5.protocol }
    let!(:step_on_task6) { create :step, name: 'task6_step', protocol: task6.protocol }

    # Positions
    let(:positions) do
      # Dinamicly generate positions stirng from tasks: "1,0,1;2,0,2;3... "
      # Skip some tasks and set position manually (happens when we move them)
      all = %i(5 6 7 8).map { |i| public_send("task#{i}") }.inject('') { |str, el| str + "#{el.id},#{el.x},#{el.y};" }
      all + "#{task1.id},0,20;"
    end
    let(:new_tasks_positions) { 'n0,1,0;n1,1,1;n2,0,1;n3,0,3;n4,4,4;n5,5,5;' }

    # Tasks for creation
    let(:task_new_items) { 'n0,n1,n2,n3,n4,n5' }
    let(:task_new_items_names) do
      'task_new1|task_new2|task_on_location_of_moved_task1|task_on_location_of_archived_task3|clone_1|clone_2'
    end

    # Tasks for archiving
    let(:task_archives) { [task4.id, task2.id, task3.id].join(',') }

    # Tasks for moving
    let(:task_moves) { Hash[task7.id.to_s, experiment2.id.to_s, 'n1', experiment2.id.to_s].to_json }

    # Tasks for renaming
    let(:task_renames) { Hash[task1.id, 'RenamedTask1', task2.id, 'RenamedTask2', task6.id, 'RenamedTask6'].to_json }

    # Tasks for cloning
    let(:task_clones) { "#{task5.id},n4;#{task6.id},n5" }

    let(:action) { post :update, params: params, format: :json }
    let(:params) do
      {
        id: experiment.id,
        positions: positions + new_tasks_positions,
        add: task_new_items,
        'add-names': task_new_items_names,
        rename: task_renames,
        move: task_moves,
        remove: task_archives,
        cloned: task_clones
      }
    end

    context 'when have a lot changes on canvas' do
      it 'everything goes right, redirected to canvas' do
        action
        [task1, task2, task3, task6].each(&:reload)

        # Expectations
        # task1 Renamed and moved
        expect(task1.name).to be_eql('RenamedTask1')
        expect({ x: task1.x, y: task1.y }).to(be_eql({ x: 0, y: 20 }))

        # task2 Renamed and archived
        expect(task2.name).to be_eql('RenamedTask2')
        expect(task2).to be_archived

        # task3 Archive
        expect(task3).to be_archived

        # task6 Renamed
        expect(task6.name).to be_eql('RenamedTask6')

        # create new n4 on position of the archived Task3
        expect(experiment.my_modules.find_by(x: 0, y: 3).name).to(be_eql('task_on_location_of_archived_task3'))

        # Add new task n2 on the place of existing task1, previous location
        expect(experiment.my_modules.find_by(x: 0, y: 1).name).to(be_eql('task_on_location_of_moved_task1'))

        # 5 new tasks added to Experiment (clones included)
        names = %w(task_new1 task_on_location_of_moved_task1 task_on_location_of_archived_task3 clone_1 clone_2)
        new_tasks_count = experiment.my_modules.where(name: names).count
        expect(new_tasks_count).to(be_eql(5))

        # Experiment 2 has change for 2 (moved 2 tasks from Experiment to Experiment2)
        expect(experiment2.my_modules.count).to(be_eql(2))

        # # Check clones, task5, task6
        expect(experiment.my_modules.find_by(name: 'clone_1').protocol.steps.first.name).to(be_eql('task5_step'))
        expect(experiment.my_modules.find_by(name: 'clone_2').protocol.steps.first.name).to(be_eql('task6_step'))

        expect(response).to redirect_to canvas_experiment_path(experiment)
      end
    end
  end
end
