class RapProgramLevelController < ApplicationController
  respond_to :html, :js

  def render_dropdown_partial
    @programs_from_controller = RapProgramLevel.pluck(:name)
  end

  def show
    # In the view, we can reference programs without the @ sign (since we made it local)
    render :template => "rap_program_level/dropdown.html.erb", :locals => { :programs => RapProgramLevel.pluck(:name) }
  end
end