# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren

class Reports::Docx
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  include InputSanitizeHelper
  include TeamsHelper
<<<<<<< HEAD
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
=======
  include GlobalActivitiesHelper
  include RepositoryDatatableHelper

  Dir[File.join(File.dirname(__FILE__), 'docx') + '**/*.rb'].each do |file|
    include_module = File.basename(file).gsub('.rb', '').split('_').map(&:capitalize).join
    include "Reports::Docx::#{include_module}".constantize
  end

  def initialize(json, docx, options)
    @json = JSON.parse(json)
    @docx = docx
    @user = options[:user]
    @report_team = options[:team]
>>>>>>> Finished merging. Test on dev machine (iMac).
    @link_style = {}
    @color = {}
    @scinote_url = options[:scinote_url][0..-2]
  end

  def draw
    initial_document_load

<<<<<<< HEAD
    @report.root_elements.each do |subject|
      public_send("draw_#{subject.type_of}", subject)
    end
    @docx
  end
end
=======
    @json.each do |subject|
      public_send("draw_#{subject['type_of']}", subject)
    end
    @docx
  end


  def self.link_prepare(scinote_url, link)
    link[0] == '/' ? scinote_url + link : link
  end
end

>>>>>>> Finished merging. Test on dev machine (iMac).
# rubocop:enable  Style/ClassAndModuleChildren
