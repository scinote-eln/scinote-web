# frozen_string_literal: true

class DesignElementsController < ApplicationController
  def index; end

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
end
