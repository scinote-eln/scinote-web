# frozen_string_literal: true

module QaTools
  class DesignElementsController < ApplicationController
    # The page is rendered from this list, in this order.
    # To add a component: create its partial and add one entry under its family.
    # `id` is the section's anchor (/qa_tools/design_elements#id): the component name,
    # singular, kebab-case. It must not clash with a Vue mount element id inside a partial.
    SECTIONS = [
      { family: 'Foundations', items: [
        { name: 'Colors', partial: 'colors', id: 'color' },
        { name: 'Icons', partial: 'icons', id: 'icon' }
      ] },
      { family: 'Action', items: [
        { name: 'Button', partial: 'button', id: 'button' }
      ] },
      { family: 'Form', items: [
        { name: 'Checkbox', partial: 'checkbox', id: 'checkbox' },
        { name: 'Radio', partial: 'radio', id: 'radio' },
        { name: 'Toggle', partial: 'toggle', id: 'toggle' },
        { name: 'Input field', partial: 'inputs', id: 'input-field' },
        { name: 'Title field', partial: 'input_title', id: 'title-field' },
        { name: 'Select', partial: 'select', id: 'select' },
        { name: 'Date time picker', partial: 'datepicker', id: 'date-time-picker' }
      ] },
      { family: 'Feedback', items: [
        { name: 'Toast', partial: 'toast', id: 'toast' },
        { name: 'Loader', partial: 'misc', id: 'loader' }
      ] },
      { family: 'Navigation', items: [
        { name: 'Breadcrumbs', partial: 'breadcrumbs', id: 'breadcrumb' },
        { name: 'Tabs', partial: 'tabs', id: 'tab' }
      ] },
      { family: 'Overlay', items: [
        { name: 'Modals', partial: 'modals', id: 'modal' }
      ] },
      { family: 'Data display', items: [
        { name: 'Tags', partial: 'tags', id: 'tag' },
        { name: 'Table', partial: 'table', id: 'data-table' },
        { name: 'Charts', partial: 'charts', id: 'chart' }
      ] }
    ].freeze

    def index
      @sections = SECTIONS
      @icons_list = icons_list
      @colors_list = colors_list
    end

    def test_select
      render json: { data: [
        %w(1 One),
        %w(2 Two),
        %w(3 Three),
        %w(4 Four),
        %w(5 Five),
        %w(6 Six),
        %w(7 Seven),
        %w(8 Eight),
        %w(9 Nine),
        %w(10 Ten)
      ].select { |item| item[1].downcase.include?(params[:query].downcase) } }
    end

    def test_table
      render json: {
        data: [
          { id: 1, attributes: {
            name: 'One',
            description: nil,
            date: {
              value: I18n.l(DateTime.now, format: :default),
              value_formatted: I18n.l(DateTime.now, format: :full_date),
              editable: true
            }
          } },
          { id: 2, attributes: { name: 'Two', description: '[@admin~1]', date: { editable: true } } },
          { id: 3,
            attributes: { name: 'Three', description: 'Long long long long name Long long long long name Long long long long name Long long long long name',
                          date: { editable: true } } },
          { id: 4, attributes: { name: 'Four', date: { editable: true } } }
        ],
        meta: {
          current_page: 1,
          next_page: nil,
          prev_page: nil,
          total_pages: 1,
          total_count: 4
        }
      }
    end

    private

    # Icon names from the SN icon font, e.g. "close" for .sn-icon-close.
    def icons_list
      File.foreach(Rails.root.join('vendor/assets/stylesheets/sn-icon-font.css')).filter_map do |line|
        line[/sn-icon-([a-z0-9-]+):before/, 1]
      end
    end

    # The sn-* colour tokens with a hex value from the Tailwind config.
    def colors_list
      File.foreach(Rails.root.join('config/tailwind.config.js')).filter_map do |line|
        match = line.match(/['"]?(sn-[a-z0-9-]+)['"]?\s*:\s*['"]?([#a-zA-Z0-9]+)['"]?/)
        { name: match[1], value: match[2] } if match && match[2].include?('#')
      end
    end
  end
end
