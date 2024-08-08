# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren

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
  end

  def draw
    initial_document_load

    @docx.header do |header|
      header.p 'ID'
      header.p 'Test header', bold: true
      header.p
    end

    @docx.footer do |footer|
      footer.p do
        align :center
        text 'Confidential'
        text '                                                                                                                       '
        field :page
        text ' of '
        field :numpages
      end
    end

    @docx.table_of_contents do |toc|
      toc.title 'Table of Contents'
      toc.opts 'TOC \o "1-4" \h \z \u \t "Heading 5,1"'
    end

    @docx.page

    my_modules_element = []
    @report.root_elements.each do |subject|
      if subject.type_of == 'experiment'
        my_modules_element += subject.children.active
      end
    end

    my_modules = []
    assigned_items = []

    my_modules_element.each do |element|
      my_modules << element.my_module
      element.children.active.each do |child|
        if child.type_of == 'my_module_repository'
          assigned_items << child
        end
      end
    end


    @docx.h1 'Materials'
    assigned_items.each do |assigned_item|
      draw_my_module_repository(assigned_item)
    end
    @docx.page
    @docx.h1 'Methods'
    my_modules.each do |my_module|
      draw_my_module_protocol(my_module)
      filter_steps_for_report(my_module.protocol.steps, @settings).order(:position).each do |step|
       draw_step(step)
      end
    end
    @docx.page
    @docx.h1 'Results'
    my_modules.each do |my_module|
      if my_module.results.any? && (%w(file_results table_results text_results).any? { |k| @settings.dig('task', k) })
        order_results_for_report(my_module.results, @settings.dig('task', 'result_order')).each do |result|
          @docx.h4 do
            text result.name.presence || I18n.t('projects.reports.unnamed'), italic: true
            text "  #{I18n.t('search.index.archived')} ", bold: true if result.archived?
          end
          draw_result_asset(result, @settings) if @settings.dig('task', 'file_results')
          result.result_orderable_elements.each do |element|
            if @settings.dig('task', 'table_results') && element.orderable_type == 'ResultTable'
              draw_result_table(element)
            elsif @settings.dig('task', 'text_results') && element.orderable_type == 'ResultText'
              draw_result_text(element)
            end
          end
          @docx.p
          @docx.p
        end
      end
    end



   # @report.root_elements.each do |subject|
   #   public_send("draw_#{subject.type_of}", subject)
   # end

    @docx
  end
end
# rubocop:enable  Style/ClassAndModuleChildren
