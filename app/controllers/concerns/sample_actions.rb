module SampleActions
  extend ActiveSupport::Concern
  include PermissionHelper

  def delete_samples
    check_destroy_samples_permissions
    
    if params[:sample_ids].present?
      counter_user = 0
      counter_other_users = 0
      params[:sample_ids].each do |id|
        sample = Sample.find_by_id(id)

        if sample and can_delete_sample(sample)
          sample.destroy
          counter_user += 1
        else 
          counter_other_users += 1
        end
      end
      if counter_user > 0
        if counter_other_users > 0
          flash[:success] = t("samples.destroy.contains_other_samples_flash", 
            sample_number: counter_user, other_samples_number: counter_other_users)  
        else
          flash[:success] = t("samples.destroy.success_flash", 
            sample_number: counter_user)
        end
      else 
        flash[:notice] = t("samples.destroy.no_deleted_samples_flash", 
        other_samples_number: counter_other_users)
      end
    else
      flash[:notice] = t("samples.destroy.no_sample_selected_flash")
    end

    if params[:controller] == "my_modules"
      redirect_to samples_my_module_path(@my_module)
    elsif params[:controller] == "projects"
      redirect_to samples_project_path(@project)
    end
  end

  def check_destroy_samples_permissions
    unless can_delete_samples(@project.organization)
      render_403
    end
  end
end
