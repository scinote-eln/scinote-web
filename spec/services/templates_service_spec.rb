# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'

describe TemplatesService do
  let!(:main_team) { create :team }
  let!(:admin_user) { create :user }

  describe '#update_project' do
    context 'update templates project' do
      it 'experiment is added to templates project' do
        create(:user_team, user: admin_user, team: main_team)
        dj_worker = Delayed::Worker.new
        templates_project =
          create :project, name: 'Templates', template: true, team: main_team
        create(
          :user_project, :owner, project: templates_project, user: admin_user
        )
        ts = TemplatesService.new
        ts.update_team(main_team)
        Delayed::Job.all.each { |job| dj_worker.run(job) }
        tmpl_exp = templates_project.experiments.find_by(name: 'Polymerase chain reaction')

        expect(tmpl_exp.uuid).to_not eq(nil)
        expect(tmpl_exp.my_modules.pluck(:name))
          .to match_array(['Data analysis - ddCq', 'Data quality control', 'Experiment design', 'qPCR',
                           'Reverse transcription', 'RNA isolation', 'RNA quality & quantity - BIOANALYSER',
                           'Sampling biological material'])
        tmpl_tasks = tmpl_exp.my_modules
        tmpl_tasks.each do |tmpl_task|
          tmpl_task.protocol.steps.each do |tmpl_step|
            tmpl_step.assets.each do |asset|
              expect(asset.file.attached?).to eq(true)
            end
          end
        end
      end
    end
  end
end
