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
        # Two runs are needed to execute additional jobs which get generated
        # during first run
        Delayed::Job.all.each { |job| dj_worker.run(job) }
        Delayed::Job.all.each { |job| dj_worker.run(job) }
        demo_exp = main_team.projects.first.experiments.first
        exp_exporter = ModelExporters::ExperimentExporter.new(demo_exp.id)
        exp_dir = exp_exporter.export_template_to_dir
        tmplts_dir = "#{Rails.root}/tmp/testing_templates"
        FileUtils.remove_dir(tmplts_dir) if Dir.exist?(tmplts_dir)
        FileUtils.mkdir(tmplts_dir)
        FileUtils.mv(exp_dir, "#{tmplts_dir}/experiment_#{demo_exp.id}")
        templates_project =
          create :project, name: 'Templates', template: true, team: main_team
        create(
          :user_project, :owner, project: templates_project, user: admin_user
        )
        ts = TemplatesService.new(tmplts_dir)
        ts.update_team(main_team)
        Delayed::Job.all.each { |job| dj_worker.run(job) }
        tmpl_exp = templates_project.experiments.first

        expect(tmpl_exp.name).to eq(demo_exp.name)
        expect(tmpl_exp.uuid).to_not eq(nil)
        expect(tmpl_exp.my_modules.pluck(:name))
          .to match_array(demo_exp.active_my_modules.pluck(:name))
        tmpl_tasks = tmpl_exp.my_modules
        demo_tasks = demo_exp.active_my_modules
        demo_tasks.each do |demo_task|
          tmpl_task = tmpl_tasks.find_by_name(demo_task.name)
          expect(tmpl_task.name).to eq(demo_task.name)
          expect(tmpl_task.task_comments.size)
            .to eq(demo_task.task_comments.size)
          demo_task.results.each do |demo_res|
            tmpl_res = tmpl_task.results.find_by_name(demo_res.name)
            expect(tmpl_res.name).to eq(demo_res.name)
            if demo_res.asset
              expect(tmpl_res.asset.file.attached?).to eq(true)
              expect(demo_res.asset.file_name)
                .to eq(tmpl_res.asset.file_name)
            elsif demo_res.table
              expect(demo_res.table.contents).to eq(tmpl_res.table.contents)
            elsif demo_res.result_text
              expect(demo_res.result_text.text).to eq(tmpl_res.result_text.text)
            end
            expect(demo_res.result_comments.size)
              .to eq(tmpl_res.result_comments.size)
          end
          unless demo_task.protocol.present? &&
                 demo_task.protocol.steps.size.positive?
            next
          end

          demo_task.protocol.steps.each do |demo_step|
            tmpl_step = tmpl_task.protocol.steps.find_by_name(demo_step.name)
            expect(demo_step.name).to eq(tmpl_step.name)
            expect(demo_step.description).to eq(tmpl_step.description)
            if demo_step.assets.present?
              expect(demo_step.assets.map(&:file_name))
                .to match_array(tmpl_step.assets.map(&:file_name))
            end
            tmpl_step.assets.each do |asset|
              expect(asset.file.attached?).to eq(true)
            end
            if demo_step.tables.present?
              expect(demo_step.tables.pluck(:contents))
                .to match_array(tmpl_step.tables.pluck(:contents))
            end
            if demo_step.checklists.present?
              expect(demo_step.checklists.pluck(:name))
                .to match_array(tmpl_step.checklists.pluck(:name))
            end
            expect(demo_step.step_comments.size)
              .to eq(tmpl_step.step_comments.size)
          end
        end
        FileUtils.remove_dir(tmplts_dir)
      end
    end
  end
end
