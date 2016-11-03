Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations",
    sessions: "users/sessions", invitations: "users/invitations",
    confirmations: "users/confirmations" }

  root 'projects#index'

  resources :activities, only: [:index]

  get "forbidden", :to => "application#forbidden", as: "forbidden"
  get "not_found", :to => "application#not_found", as: "not_found"

  # Settings
  get "users/settings/preferences", to: "users/settings#preferences", as: "preferences"
  put "users/settings/preferences", to: "users/settings#update_preferences", as: "update_preferences"
  get "users/settings/preferences/tutorial", to: "users/settings#tutorial", as: "tutorial"
  post "users/settings/preferences/reset_tutorial/", to: "users/settings#reset_tutorial", as: "reset_tutorial"
  post 'users/settings/preferences/notifications_settings',
       to: 'users/settings#notifications_settings',
       as: 'notifications_settings',
       defaults: { format: 'json' }
  post 'users/settings/user_current_organization',
       to: 'users/settings#user_current_organization',
       as: 'user_current_organization'
  get "users/settings/organizations", to: "users/settings#organizations", as: "organizations"
  get "users/settings/organizations/new", to: "users/settings#new_organization", as: "new_organization"
  post "users/settings/organizations/new", to: "users/settings#create_organization", as: "create_organization"
  get "users/settings/organizations/:organization_id", to: "users/settings#organization", as: "organization"
  put "users/settings/organizations/:organization_id", to: "users/settings#update_organization", as: "update_organization"
  get "users/settings/organizations/:organization_id/name", to: "users/settings#organization_name", as: "organization_name"
  get "users/settings/organizations/:organization_id/description", to: "users/settings#organization_description", as: "organization_description"
  get "users/settings/organizations/:organization_id/search", to: "users/settings#search_organization_users", as: "search_organization_users"
  post "users/settings/organizations/:organization_id/users_datatable", to: "users/settings#organization_users_datatable", as: "organization_users_datatable"
  delete "users/settings/organizations/:organization_id", to: "users/settings#destroy_organization", as: "destroy_organization"
  post "users/settings/user_organizations/new", to: "users/settings#create_user_organization", as: "create_user_organization"
  post "users/settings/users_organizations/new_user", to: "users/settings#create_user_and_user_organization", as: "create_user_and_user_organization"
  put "users/settings/user_organizations/:user_organization_id", to: "users/settings#update_user_organization", as: "update_user_organization"
  get "users/settings/user_organizations/:user_organization_id/leave_html", to: "users/settings#leave_user_organization_html", as: "leave_user_organization_html"
  get "users/settings/user_organizations/:user_organization_id/destroy_html", to: "users/settings#destroy_user_organization_html", as: "destroy_user_organization_html"
  delete "users/settings/user_organizations/:user_organization_id", to: "users/settings#destroy_user_organization", as: "destroy_user_organization"

  # Invite users
  post 'users/invite',
       to: 'users/invitations#invite_users',
       as: 'invite_users'

  # Notifications
  get 'users/:id/recent_notifications',
      to: 'user_notifications#recent_notifications',
      as: 'recent_notifications',
      defaults: { format: 'json' }

  get 'users/:id/unseen_notification',
      to: 'user_notifications#unseen_notification',
      as: 'unseen_notification',
      defaults: { format: 'json' }

  get 'users/notifications',
      to: 'user_notifications#index',
      as: 'notifications'

  resources :organizations, only: [] do
    resources :samples, only: [:new, :create]
    resources :sample_types, only: [:new, :create]
    resources :sample_groups, only: [:new, :create]
    resources :custom_fields, only: [:create]
    member do
      post 'parse_sheet'
      post 'import_samples'
      post 'export_samples'
    end
    match '*path', :to  => 'organizations#routing_error', via: [:get, :post, :put, :patch]
  end

  get 'projects/archive', to: 'projects#archive', as: 'projects_archive'

  resources :projects, except: [:new, :destroy] do
    resources :user_projects, path: "/users", only: [:new, :create, :index, :edit, :update, :destroy]
    resources :project_comments,
              path: '/comments',
              only: [:new, :create, :index, :edit, :update, :destroy]
    # Activities popup (JSON) for individual project in projects index,
    # as well as all activities page for single project (HTML)
    resources :project_activities, path: "/activities", only: [:index]
    resources :tags, only: [:create, :update, :destroy]
    resources :reports, path: "/reports", only: [:index, :new, :create, :edit, :update] do
      collection do
        # The posts following here should in theory be gets,
        # but are posts because of parameters payload
        post 'generate', to: 'reports#generate'
        get 'new/', to: 'reports#new'
        get 'new/project_contents_modal',
            to: 'reports#project_contents_modal',
            as: :project_contents_modal
        post 'new/project_contents',
             to: 'reports#project_contents',
             as: :project_contents
        get 'new/experiment_contents_modal',
            to: 'reports#experiment_contents_modal',
            as: :experiment_contents_modal
        post 'new/experiment_contents',
             to: 'reports#experiment_contents',
             as: :experiment_contents
        get 'new/module_contents_modal',
            to: 'reports#module_contents_modal',
            as: :module_contents_modal
        post 'new/module_contents',
             to: 'reports#module_contents',
             as: :module_contents
        get 'new/step_contents_modal',
            to: 'reports#step_contents_modal',
            as: :step_contents_modal
        post 'new/step_contents',
             to: 'reports#step_contents',
             as: :step_contents
        get 'new/result_contents_modal',
            to: 'reports#result_contents_modal',
            as: :result_contents_modal
        post 'new/result_contents',
             to: 'reports#result_contents',
             as: :result_contents
        post '_save',
             to: 'reports#save_modal',
             as: :save_modal
        post 'destroy', as: :destroy # Destroy multiple entries at once
      end
    end
    resources :experiments,
              only: [:new, :create, :edit, :update],
              defaults: { format: 'json' }
    member do
      get 'notifications' # Notifications popup for individual project in projects index
      get 'samples' # Samples for single project
      post 'samples_index' # Renders sample datatable for single project (ajax action)
      get 'experiment_archive' # Experiment archive for single project
      post :delete_samples, constraints: CommitParamRouting.new(MyModulesController::DELETE_SAMPLES), action: :delete_samples
    end

    # This route is defined outside of member block to preserve original :project_id parameter in URL.
    get 'users/edit', to: 'user_projects#index_edit'
  end

  resources :experiments do
    member do
      get 'canvas' # Overview/structure for single experiment
      # AJAX-loaded canvas edit mode (from canvas)
      get 'canvas/edit', to: 'canvas#edit'
      get 'canvas/full_zoom', to: 'canvas#full_zoom' # AJAX-loaded canvas zoom
      # AJAX-loaded canvas zoom
      get 'canvas/medium_zoom', to: 'canvas#medium_zoom'
      get 'canvas/small_zoom', to: 'canvas#small_zoom' # AJAX-loaded canvas zoom
      post 'canvas', to: 'canvas#update' # Save updated canvas action
      get 'module_archive' # Module archive for single experiment
      get 'archive' # archive experiment
      get 'clone_modal' # return modal with clone options
      post 'clone' # clone experiment
      get 'move_modal' # return modal with move options
      post 'move' # move experiment
      get 'samples' # Samples for single project
      get 'updated_img' # Checks if the workflow image is updated
      get 'fetch_workflow_img' # Get udated workflow img
      # Renders sample datatable for single project (ajax action)
      post 'samples_index'
      post :delete_samples,
           constraints: CommitParamRouting.new(
             MyModulesController::DELETE_SAMPLES
           ),
           action: :delete_samples
    end
  end

  # Show action is a popup (JSON) for individual module in full-zoom canvas,
  # as well as "module info" page for single module (HTML)
  resources :my_modules, path: "/modules", only: [:show, :edit, :update, :destroy] do
    resources :my_module_tags, path: "/tags", only: [:index, :create, :update, :destroy]
    resources :user_my_modules, path: "/users", only: [:index, :new, :create, :destroy]
    resources :my_module_comments,
              path: '/comments',
              only: [:index, :new, :create, :edit, :update, :destroy]
    resources :sample_my_modules, path: "/samples_index", only: [:index]
    resources :result_texts, only: [:new, :create]
    resources :result_assets, only: [:new, :create]
    resources :result_tables, only: [:new, :create]
    member do
      # AJAX popup accessed from full-zoom canvas for single module,
      # as well as full activities view (HTML) for single module
      get 'description'
      get 'activities'
      get 'activities_tab' # Activities in tab view for single module
      get 'due_date'
      get 'protocols' # Protocols view for single module
      get 'results' # Results view for single module
      get 'samples' # Samples view for single module
      get 'archive' # Archive view for single module
      post 'samples_index' # Renders sample datatable for single module (ajax action)
      post :assign_samples, constraints: CommitParamRouting.new(MyModulesController::ASSIGN_SAMPLES), action: :assign_samples
      post :assign_samples, constraints: CommitParamRouting.new(MyModulesController::UNASSIGN_SAMPLES), action: :unassign_samples
      post :assign_samples, constraints: CommitParamRouting.new(MyModulesController::DELETE_SAMPLES), action: :delete_samples
    end

    # Those routes are defined outside of member block to preserve original id parameters in URL.
    get 'tags/edit', to: 'my_module_tags#index_edit'
    get 'users/edit', to: 'user_my_modules#index_edit'
  end

  resources :steps, only: [:edit, :update, :destroy, :show] do
    resources :step_comments,
              path: '/comments',
              only: [:new, :create, :index, :edit, :update, :destroy]
    member do
      post 'checklistitem_state'
      post 'toggle_step_state'
      get 'move_down'
      get 'move_up'
    end
  end

  resources :results, only: [:update, :destroy] do
    resources :result_comments,
              path: '/comments',
              only: [:new, :create, :index, :edit, :update, :destroy]
  end

  resources :samples, only: [:edit, :update, :destroy]
  get 'samples/:id', to: 'samples#show'

  resources :sample_types, only: [:edit, :update]
  resources :sample_groups, only: [:edit, :update]
  resources :result_texts, only: [:edit, :update, :destroy]
  get 'result_texts/:id/download' => 'result_texts#download',
    as: :result_text_download
  resources :result_assets, only: [:edit, :update, :destroy]
  get 'result_assets/:id/download' => 'result_assets#download',
    as: :result_asset_download
  resources :result_tables, only: [:edit, :update, :destroy]
  get 'result_tables/:id/download' => 'result_tables#download',
    as: :result_table_download

  resources :protocols, only: [:index, :edit, :create] do
    resources :steps, only: [:new, :create]
    member do
      get "linked_children", to: "protocols#linked_children"
      post "linked_children_datatable", to: "protocols#linked_children_datatable"
      patch "metadata", to: "protocols#update_metadata"
      patch "keywords", to: "protocols#update_keywords"
      post "clone", to: "protocols#clone"
      get "unlink_modal", to: "protocols#unlink_modal"
      post "unlink", to: "protocols#unlink"
      get "revert_modal", to: "protocols#revert_modal"
      post "revert", to: "protocols#revert"
      get "update_parent_modal", to: "protocols#update_parent_modal"
      post "update_parent", to: "protocols#update_parent"
      get "update_from_parent_modal", to: "protocols#update_from_parent_modal"
      post "update_from_parent", to: "protocols#update_from_parent"
      post "load_from_repository_datatable", to: "protocols#load_from_repository_datatable"
      get "load_from_repository_modal", to: "protocols#load_from_repository_modal"
      post "load_from_repository", to: "protocols#load_from_repository"
      post "load_from_file", to: "protocols#load_from_file"
      get "copy_to_repository_modal", to: "protocols#copy_to_repository_modal"
      post "copy_to_repository", to: "protocols#copy_to_repository"
      get "protocol_status_bar", to: "protocols#protocol_status_bar"
      get "updated_at_label", to: "protocols#updated_at_label"
      get "edit_name_modal", to: "protocols#edit_name_modal"
      get "edit_keywords_modal", to: "protocols#edit_keywords_modal"
      get "edit_authors_modal", to: "protocols#edit_authors_modal"
      get "edit_description_modal", to: "protocols#edit_description_modal"
    end
    collection do
      get "create_new_modal", to: "protocols#create_new_modal"
      post "datatable", to: "protocols#datatable"
      post "make_private", to: "protocols#make_private"
      post "publish", to: "protocols#publish"
      post "archive", to: "protocols#archive"
      post "restore", to: "protocols#restore"
      post "import", to: "protocols#import"
      get "export", to: "protocols#export"
    end
  end

  get 'search' => 'search#index'
  get 'search/new' => 'search#new', as: :new_search

  # We cannot use 'resources :assets' because assets is a reserved route
  # in Rails (assets pipeline) and causes funky behavior
  get "files/:id/present", to: "assets#file_present", as: "file_present_asset"
  get "files/:id/download", to: "assets#download", as: "download_asset"
  get "files/:id/preview", to: "assets#preview", as: "preview_asset"
  post 'asset_signature' => 'assets#signature'

  devise_scope :user do
    get 'avatar/:id/:style' => 'users/registrations#avatar', as: 'avatar'
    post 'avatar_signature' => 'users/registrations#signature'
  end
end
