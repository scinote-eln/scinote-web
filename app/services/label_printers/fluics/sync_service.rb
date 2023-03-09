# frozen_string_literal: true

module LabelPrinters
  module Fluics
    class SyncService
      def initialize(user = nil, team = nil)
        @user = user
        @team = team
      end

      def sync_templates!
        LabelPrinter.fluics.each do |printer|
          api_client = ApiClient.new(printer.fluics_api_key)
          templates = api_client.list_templates
          templates.each do |template|
            update_team!(@team, template) && next if @team.present?

            Team.find_each do |team|
              update_team!(team, template)
            end
          end
        end
      end

      private

      def update_team!(team, template)
        persisted_template = FluicsLabelTemplate.where(team: team).find_by(name: template['id'])

        if persisted_template.present?
          persisted_template.assign_attributes(description: template['comment'],
                                               content: template['template'],
                                               width_mm: template['width'],
                                               height_mm: template['height'])
          if persisted_template.changed?
            persisted_template.last_modified_by = @user
            persisted_template.save!
          end
        else
          FluicsLabelTemplate.create!(team: team,
                                      name: template['id'],
                                      description: template['comment'],
                                      content: template['template'],
                                      width_mm: template['width'],
                                      height_mm: template['height'],
                                      created_by: @user)
        end
      end
    end
  end
end
