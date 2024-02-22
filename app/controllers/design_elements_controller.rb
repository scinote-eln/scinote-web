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
end
