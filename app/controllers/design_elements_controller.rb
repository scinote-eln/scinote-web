class DesignElementsController < ApplicationController
  def index
  end

  def test_select
    render json: { data: [
      ['1', 'One'],
      ['2', 'Two'],
      ['3', 'Three'],
      ['4', 'Four'],
      ['5', 'Five'],
      ['6', 'Six'],
      ['7', 'Seven'],
      ['8', 'Eight'],
      ['9', 'Nine'],
      ['10', 'Ten']
    ].select { |item| item[1].downcase.include?(params[:query].downcase) } }
  end

  def test_table
    render json: {
      data: [
        { id: 1, attributes: {name: 'One' } },
        { id: 2, attributes: {name: 'Two' } },
        { id: 3, attributes: {name: 'Three' } },
        { id: 4, attributes: {name: 'Four' } },
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
