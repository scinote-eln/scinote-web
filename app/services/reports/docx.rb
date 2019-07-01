# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren

class Reports::Docx
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  include InputSanitizeHelper
  include TeamsHelper
  include GlobalActivitiesHelper
  include RepositoryDatatableHelper

  Dir[File.join(File.dirname(__FILE__), 'docx') + '**/*.rb'].each do |file|
    require file
    include_module = File.basename(file).gsub('.rb', '').split('_').map(&:capitalize).join
    include include_module.constantize
  end

  def initialize(json, docx, options)
    @json = JSON.parse(json)
    @docx = docx
    @user = options[:user]
    @report_team = options[:team]
    @link_style = {}
    @color = {}
    @scinote_url = options[:scinote_url][0..-2]
  end

  def draw
    initial_document_load

    @json.each do |subject|
      public_send("draw_#{subject['type_of']}", subject)
    end
    @docx
  end
end

# rubocop:enable  Style/ClassAndModuleChildren
