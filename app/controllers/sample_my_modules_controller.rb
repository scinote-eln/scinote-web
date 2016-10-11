class SampleMyModulesController < ApplicationController
  before_action :load_vars

  def index
    @number_of_samples = @my_module.number_of_samples
    @samples = @my_module.first_n_samples

    current_organization_switch(@my_module
                                .experiment
                                .project
                                .organization)
    respond_to do |format|
      format.json {
        render :json => {
          :html => render_to_string({
            :partial => "index.html.erb"
            })
        }
      }
    end
  end

  private

  def load_vars
    @my_module = MyModule.find_by_id(params[:my_module_id])

    unless @my_module
      render_404
    end
  end
end
