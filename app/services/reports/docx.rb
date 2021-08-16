# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren

class Reports::Docx
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  include InputSanitizeHelper
  include TeamsHelper
<<<<<<< HEAD
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
=======
  include ReportsHelper
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
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
<<<<<<< HEAD
    @report_team = options[:team]
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
    @report_team = report.project.team
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    @link_style = {}
    @color = {}
    @scinote_url = options[:scinote_url][0..-2]
  end

  def draw
    initial_document_load

<<<<<<< HEAD
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
=======
    @report.root_elements.each do |subject|
      public_send("draw_#{subject.type_of}", subject)
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    end
    @docx
  end
end
<<<<<<< HEAD

>>>>>>> Finished merging. Test on dev machine (iMac).
=======
>>>>>>> Pulled latest release
# rubocop:enable  Style/ClassAndModuleChildren
