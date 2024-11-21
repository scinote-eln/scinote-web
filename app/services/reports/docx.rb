# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren

Dir[Rails.root.join('app/views/reports/docx_templates/**/docx.rb')].each do |file|
  require file
end

class Reports::Docx
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  include InputSanitizeHelper
  include TeamsHelper
  include ReportsHelper
  include GlobalActivitiesHelper
  include Canaid::Helpers::PermissionsHelper

  Dir[File.join(File.dirname(__FILE__), 'docx') + '**/*.rb'].each do |file|
    include_module = File.basename(file).gsub('.rb', '').split('_').map(&:capitalize).join
    include "Reports::Docx::#{include_module}".constantize
  end

  def initialize(report, docx, options)
    @report = report
    @settings = report.settings
    @docx = docx
    @user = options[:user]
    @report_team = report.project.team
    @link_style = {}
    @color = {}
    @scinote_url = options[:scinote_url][0..-2]
    @template = @settings[:docx_template].presence || 'scinote_template'

    extend "#{@template.camelize}Docx".constantize
  end

  def draw
    initial_document_load

    prepare_docx

    @docx
  end

  private

  def get_template_value(name)
    @report.report_template_values.find_by(name: name)&.value
  end
end
# rubocop:enable  Style/ClassAndModuleChildren
