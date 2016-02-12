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
    resources :project_comments, path: "/comments", only: [:new, :create, :index]
    # Activities popup (JSON) for individual project in projects index,
    # as well as all activities page for single project (HTML)
    resources :project_activities, path: "/activities", only: [:index]
    resources :tags, only: [:create, :update, :destroy]
    resources :reports, path: "/reports", only: [:index, :new, :create, :edit, :update] do
      collection do
        # The posts following here should in theory be gets,
        # but are posts because of parameters payload
        post 'generate', to: 'reports#generate'
        get 'new/by_module', to: 'reports#new_by_module'
        get 'new/by_module/project_contents_modal',
          to: 'reports#project_contents_modal',
          as: :project_contents_modal
        post 'new/by_module/project_contents',
          to: 'reports#project_contents',
          as: :project_contents
        get 'new/by_module/module_contents_modal',
          to: 'reports#module_contents_modal',
          as: :module_contents_modal
        post 'new/by_module/module_contents',
          to: 'reports#module_contents',
          as: :module_contents
        get 'new/by_module/step_contents_modal',
          to: 'reports#step_contents_modal',
          as: :step_contents_modal
        post 'new/by_module/step_contents',
          to: 'reports#step_contents',
          as: :step_contents
        get 'new/by_module/result_contents_modal',
          to: 'reports#result_contents_modal',
          as: :result_contents_modal
        post 'new/by_module/result_contents',
          to: 'reports#result_contents',
          as: :result_contents
        get 'new/by_timestamp', to: 'reports#new_by_timestamp'
        post '_save', to: 'reports#save_modal', as: :save_modal
        post 'destroy', as: :destroy  # Destroy multiple entries at once
      end
    end
    member do
      get 'canvas' # Overview/structure for single project
      get 'canvas/edit', to: 'canvas#edit' # AJAX-loaded canvas edit mode (from canvas)
      get 'canvas/full_zoom', to: 'canvas#full_zoom' # AJAX-loaded canvas zoom
      get 'canvas/medium_zoom', to: 'canvas#medium_zoom' # AJAX-loaded canvas zoom
      get 'canvas/small_zoom', to: 'canvas#small_zoom' # AJAX-loaded canvas zoom
      post 'canvas', to: 'canvas#update' # Save updated canvas action
      get 'notifications' # Notifications popup for individual project in projects index
      get 'samples' # Samples for single project
      get 'module_archive' # Module archive for single project
      post 'samples_index' # Renders sample datatable for single project (ajax action)
      post :delete_samples, constraints: CommitParamRouting.new(MyModulesController::DELETE_SAMPLES), action: :delete_samples
    end

    # This route is defined outside of member block to preserve original :project_id parameter in URL.
    get 'users/edit', to: 'user_projects#index_edit'
  end

  # Show action is a popup (JSON) for individual module in full-zoom canvas,
  # as well as "module info" page for single module (HTML)
  resources :my_modules, path: "/modules", only: [:show, :edit, :update, :destroy] do
    resources :my_module_tags, path: "/tags", only: [:index, :create, :update, :destroy]
    resources :user_my_modules, path: "/users", only: [:index, :new, :create, :destroy]
    resources :my_module_comments, path: "/comments", only: [:index, :new, :create]
    resources :sample_my_modules, path: "/samples_index", only: [:index]
    resources :steps, only: [:new, :create]
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
      get 'steps' # Steps view for single module
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
    resources :step_comments, path: "/comments", only: [:new, :create, :index]
    member do
      post 'checklistitem_state'
      post 'toggle_step_state'
      get 'move_down'
      get 'move_up'
    end
  end

  resources :results, only: [:update] do
    resources :result_comments, path: "/comments", only: [:new, :create, :index]
  end

  resources :samples, only: [:edit, :update, :destroy]
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

  get 'search' => 'search#index'
  get 'search/new' => 'search#new', as: :new_search

  resources :assets, only: [:show] do
    member do
      get :preview
      get :download
    end
  end

  post 'asset_signature' => 'assets#signature'

  devise_scope :user do
    get 'avatar/:style' => 'users/registrations#avatar', as: 'avatar'
    post 'avatar_signature' => 'users/registrations#signature'
  end
end
