# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'

describe TemplatesService do
  include FirstTimeDataGenerator
  let!(:main_team) { create :team }
  let!(:admin_user) { create :user }

  describe '#update_project' do
    context 'update templates project' do
      it 'experiment is added to templates project' do
        create(:user_team, user: admin_user, team: main_team)
        seed_demo_data(main_team.created_by, main_team)
        dj_worker = Delayed::Worker.new
        Delayed::Job.all.each { |job| dj_worker.run(job) }
        demo_exp = main_team.projects.first.experiments.first
        exp_exporter = ModelExporters::ExperimentExporter.new(demo_exp.id)
        exp_dir = exp_exporter.export_template_to_dir
        tmplts_dir = "#{Rails.root}/tmp/testing_templates"
        FileUtils.remove_dir(tmplts_dir) if Dir.exist?(tmplts_dir)
        FileUtils.mkdir(tmplts_dir)
        FileUtils.mv(exp_dir, "#{tmplts_dir}/experiment_#{demo_exp.id}")
        templates_project = create :project, name: 'Templates', template: true
        create(
          :user_project, :owner, project: templates_project, user: admin_user
        )
        ts = TemplatesService.new(tmplts_dir)
        ts.update_project(templates_project)
        tmpl_exp = templates_project.experiments.first

        expect(tmpl_exp.name).to eq demo_exp.name
        expect(tmpl_exp.uuid).to_not eq(nil)
        expect(tmpl_exp.my_modules.pluck(:name))
          .to eq(demo_exp.my_modules.pluck(:name))
        tmpl_tasks = tmpl_exp.active_my_modules
        demo_tasks = demo_exp.active_my_modules
        i = 0
        tmpl_tasks.each do
          tmpl_task = tmpl_tasks[i]
          demo_task = demo_tasks[i]
          expect(tmpl_task.name).to eq demo_task.name
          expect(tmpl_task.task_comments.size)
            .to eq demo_task.task_comments.size
          j = 0
          tmpl_task.results.each do
            tmpl_res = tmpl_task.results[j]
            demo_res = demo_task.results[j]
            expect(tmpl_res.name).to eq demo_res.name
            if demo_res.asset
              expect(tmpl_res.asset.file.exists?).to eq true
              expect(demo_res.asset.file_file_name)
                .to eq tmpl_res.asset.file_file_name
            elsif demo_res.table
              expect(demo_res.table.contents).to eq tmpl_res.table.contents
            elsif demo_res.result_text
              expect(demo_res.result_text.text).to eq tmpl_res.result_text.text
            end
            expect(demo_res.result_comments.size)
              .to eq tmpl_res.result_comments.size
            j += 1
          end
          unless demo_task.protocol.present? &&
                 demo_task.protocol.steps.size.positive?
            next
          end
          j = 0
          demo_task.protocol.steps.each do
            demo_step = demo_task.protocol.steps[j]
            tmpl_step = tmpl_task.protocol.steps[j]
            if demo_step.assets.present?
              expect(demo_step.assets.pluck(:file_file_name))
                .to eq tmpl_step.assets.pluck(:file_file_name)
            end
            tmpl_step.assets.each do |asset|
              expect(asset.file.exists?).to eq true
            end
            if demo_step.tables.present?
              expect(demo_step.tables.pluck(:contents))
                .to eq tmpl_step.tables.pluck(:contents)
            end
            if demo_step.checklists.present?
              expect(demo_step.checklists.pluck(:name))
                .to eq tmpl_step.checklists.pluck(:name)
            end
            expect(demo_step.name).to eq tmpl_step.name
            expect(demo_step.description).to eq tmpl_step.description
            expect(demo_step.step_comments.size)
              .to eq tmpl_step.step_comments.size
            j += 1
          end
          i += 1
        end
        Asset.all.each(&:paperclip_delete)
        FileUtils.remove_dir(tmplts_dir)
      end
    end
  end
end
