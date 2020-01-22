Rails.application.routes.draw do
  use_doorkeeper do
    skip_controllers :applications, :authorized_applications, :token_info
  end

  # Addons

  def draw(routes_name)
    instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
  end

  constraints UserSubdomain do
    devise_for :users, controllers: { registrations: 'users/registrations',
                                      sessions: 'users/sessions',
                                      invitations: 'users/invitations',
                                      confirmations: 'users/confirmations',
                                      omniauth_callbacks: 'users/omniauth_callbacks' }

    root 'projects#index'

    # # Client APP endpoints
    # get '/settings', to: 'client_api/settings#index'
    # get '/settings/*all', to: 'client_api/settings#index'
    #
    # namespace :client_api, defaults: { format: 'json' } do
    #   post '/premissions', to: 'permissions#status'
    #   %i(activities teams notifications users configurations).each do |path|
    #     draw path
    #   end
    # end

    # Save sample table state
    # post '/state_save/:team_id/:user_id',
    #      to: 'user_samples#save_samples_table_status',
    #      as: 'save_samples_table_status',
    #      defaults: { format: 'json' }
    #
    # post '/state_load/:team_id/:user_id',
    #      to: 'user_samples#load_samples_table_status',
    #      as: 'load_samples_table_status',
    #      defaults: { format: 'json' }

    resources :activities, only: [:index]

    get 'forbidden', to: 'application#forbidden', as: 'forbidden'
    get 'not_found', to: 'application#not_found', as: 'not_found'

    # JS backend helpers
    get 'helpers/to_user_date_format',
        to: 'application#to_user_date_format',
        as: 'to_user_date_format',
        defaults: { format: 'json' }

    # Settings
    resources :users, only: :index # needed for testing signup
    # needed for testing edit passowrd
    get '/users/password', to: 'devise_password#edit'

    get 'users/settings/account/preferences',
        to: 'users/settings/account/preferences#index',
        as: 'preferences'
    get 'users/settings/account/addons',
        to: 'users/settings/account/addons#index',
        as: 'addons'
    get 'users/settings/account/connected_accounts',
        to: 'users/settings/account/connected_accounts#index',
        as: 'connected_accounts'
    delete 'users/settings/account/connected_accounts',
           to: 'users/settings/account/connected_accounts#destroy',
           as: 'unlink_connected_account'
    put 'users/settings/account/preferences',
        to: 'users/settings/account/preferences#update',
        as: 'update_preferences'
    post 'users/settings/account/preferences/togglable_settings',
         to: 'users/settings/account/preferences#update_togglable_settings',
         as: 'update_togglable_settings',
         defaults: { format: 'json' }

    # Change user's current team
    post 'users/settings/user_current_team',
         to: 'users/settings#user_current_team',
         as: 'user_current_team'

    get 'users/settings/teams',
        to: 'users/settings/teams#index',
        as: 'teams'
    post 'users/settings/teams/datatable',
         to: 'users/settings/teams#datatable',
         as: 'teams_datatable'
    get 'users/settings/teams/new',
        to: 'users/settings/teams#new',
        as: 'new_team'
    post 'users/settings/teams',
         to: 'users/settings/teams#create',
         as: 'create_team'
    get 'users/settings/teams/:id',
        to: 'users/settings/teams#show',
        as: 'team'
    post 'users/settings/teams/:id/users_datatable',
         to: 'users/settings/teams#users_datatable',
         as: 'team_users_datatable'
    get 'users/settings/teams/:id/name_html',
        to: 'users/settings/teams#name_html',
        as: 'team_name'
    get 'users/settings/teams/:id/description_html',
        to: 'users/settings/teams#description_html',
        as: 'team_description'
    put 'users/settings/teams/:id',
        to: 'users/settings/teams#update',
        as: 'update_team'
    delete 'users/settings/teams/:id',
           to: 'users/settings/teams#destroy',
           as: 'destroy_team'

    put 'users/settings/user_teams/:id',
        to: 'users/settings/user_teams#update',
        as: 'update_user_team'
    get 'users/settings/user_teams/:id/leave_html',
        to: 'users/settings/user_teams#leave_html',
        as: 'leave_user_team_html'
    get 'users/settings/user_teams/:id/destroy_html',
        to: 'users/settings/user_teams#destroy_html',
        as: 'destroy_user_team_html'
    delete 'users/settings/user_teams/:id',
           to: 'users/settings/user_teams#destroy',
           as: 'destroy_user_team'

    # Invite users
    devise_scope :user do
      post '/invite',
           to: 'users/invitations#invite_users',
           as: 'invite_users'
    end

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

    # Get Zip Export
    get 'zip_exports/download/:id',
        to: 'zip_exports#download',
        as: 'zip_exports_download'

    # Get Team Zip Export
    get 'zip_exports/download_export_all_zip/:id',
        to: 'zip_exports#download_export_all_zip',
        as: 'zip_exports_download_export_all'

    get 'zip_exports/file_expired',
        to: 'zip_exports#file_expired',
        as: 'file_expired'

    resources :teams do
      resources :repositories, only: %i(index create destroy update) do
        collection do
          get 'create_modal', to: 'repositories#create_modal',
              defaults: { format: 'json' }
        end
        get 'destroy_modal', to: 'repositories#destroy_modal',
            defaults: { format: 'json' }
        get 'rename_modal', to: 'repositories#rename_modal',
            defaults: { format: 'json' }
        get 'copy_modal', to: 'repositories#copy_modal',
            defaults: { format: 'json' }
        post 'copy', to: 'repositories#copy',
             defaults: { format: 'json' }
        get :share_modal

        resources :team_repositories, only: %i(destroy) do
          collection do
            post 'update'
          end
        end
      end
      # resources :samples, only: [:new, :create]
      # resources :sample_types, except: [:show, :new] do
      #   get 'sample_type_element', to: 'sample_types#sample_type_element'
      #   get 'destroy_confirmation', to: 'sample_types#destroy_confirmation'
      # end
      # resources :sample_groups, except: [:show, :new] do
      #   get 'sample_group_element', to: 'sample_groups#sample_group_element'
      #   get 'destroy_confirmation', to: 'sample_groups#destroy_confirmation'
      # end
      # resources :custom_fields, only: [:create, :edit, :update, :destroy] do
      #   get 'destroy_html'
      # end
      member do
        post 'parse_sheet', defaults: { format: 'json' }
        post 'export_repository', to: 'repositories#export_repository'
        post 'export_projects'
        get 'export_projects_modal'
        # Used for atwho (smart annotations)
        get 'atwho_users', to: 'at_who#users'
        get 'atwho_repositories', to: 'at_who#repositories'
        get 'atwho_rep_items', to: 'at_who#rep_items'
        get 'atwho_projects', to: 'at_who#projects'
        get 'atwho_experiments', to: 'at_who#experiments'
        get 'atwho_my_modules', to: 'at_who#my_modules'
        get 'atwho_menu_items', to: 'at_who#menu_items'
      end

      # External protocols routes
      get 'list_external_protocol', to: 'external_protocols#index'
      get 'show_external_protocol', to: 'external_protocols#show'
      get 'build_external_protocol', to: 'external_protocols#new'
      post 'import_external_protocol', to: 'external_protocols#create'

      match '*path',
            to: 'teams#routing_error',
            via: [:get, :post, :put, :patch]
    end

    post 'projects/index_dt', to: 'projects#index_dt', as: 'projects_index_dt'
    get 'projects/sidebar', to: 'projects#sidebar', as: 'projects_sidebar'
    get 'projects/dt_state_load', to: 'projects#dt_state_load',
                                  as: 'projects_dt_state_load'

    resources :reports, only: :index
    get 'reports/datatable', to: 'reports#datatable'
    post 'reports/visible_projects', to: 'reports#visible_projects',
                                     defaults: { format: 'json' }
    post 'reports/available_repositories', to: 'reports#available_repositories',
                                           defaults: { format: 'json' }
    post 'reports/save_pdf_to_inventory_item',
         to: 'reports#save_pdf_to_inventory_item',
         defaults: { format: 'json' }
    post 'available_asset_type_columns',
          to: 'repository_columns#available_asset_type_columns',
          defaults: { format: 'json' }
    post 'reports/destroy', to: 'reports#destroy'

    resources :projects, except: [:new, :destroy] do
      resources :user_projects, path: '/users',
                only: [:create, :index, :update, :destroy]
      resources :project_comments,
                path: '/comments',
                only: [:create, :index, :edit, :update, :destroy]
      # Activities popup (JSON) for individual project in projects index,
      # as well as all activities page for single project (HTML)
      resources :project_activities, path: '/activities', only: [:index]
      resources :tags, only: [:create, :update, :destroy]
      resources :reports,
                path: '/reports',
                only: %i(edit update create) do
        collection do
          # The posts following here should in theory be gets,
          # but are posts because of parameters payload
          post 'generate', to: 'reports#generate', format: %w(docx pdf)
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
        end
      end
      resources :experiments,
                only: [:new, :create, :edit, :update],
                defaults: { format: 'json' }
      member do
        # Notifications popup for individual project in projects index
        get 'notifications'
        # get 'samples' # Samples for single project
        # Renders sample datatable for single project (ajax action)
        # post 'samples_index'
        get 'experiment_archive' # Experiment archive for single project
        # post :delete_samples,
        #      constraints: CommitParamRouting.new(
        #        ProjectsController::DELETE_SAMPLES
        #      ),
        #      action: :delete_samples
      end

      # This route is defined outside of member block
      # to preserve original :project_id parameter in URL.
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
        get 'my_module_tags', to: 'my_module_tags#canvas_index'
        get 'archive' # archive experiment
        get 'clone_modal' # return modal with clone options
        post 'clone' # clone experiment
        get 'move_modal' # return modal with move options
        post 'move' # move experiment
        # get 'samples' # Samples for single project
        get 'updated_img' # Checks if the workflow image is updated
        get 'fetch_workflow_img' # Get udated workflow img
        # Renders sample datatable for single project (ajax action)
      #   post 'samples_index'
      #   post :delete_samples,
      #        constraints: CommitParamRouting.new(
      #          ExperimentsController::DELETE_SAMPLES
      #        ),
      #        action: :delete_samples
      end
    end

    # Show action is a popup (JSON) for individual module in full-zoom canvas,
    # as well as 'module info' page for single module (HTML)
    resources :my_modules, path: '/modules', only: [:show, :update] do
      resources :my_module_tags, path: '/tags', only: [:index, :create, :destroy] do
        collection do
          get :search_tags
        end
        member do
          post :destroy_by_tag_id
        end
      end
      resources :user_my_modules, path: '/users',
                only: [:index, :create, :destroy]
      resources :my_module_comments,
                path: '/comments',
                only: [:index, :create, :edit, :update, :destroy]
      # resources :sample_my_modules, path: '/samples_index', only: [:index]
      resources :result_texts, only: [:new, :create]
      resources :result_assets, only: [:new, :create]
      resources :result_tables, only: [:new, :create]
      member do
        # AJAX popup accessed from full-zoom canvas for single module,
        # as well as full activities view (HTML) for single module
        get 'description'
        get 'activities'
        post 'activities'
        get 'activities_tab' # Activities in tab view for single module
        get 'due_date'
        patch 'description',
              to: 'my_modules#update_description',
              as: 'update_description'
        patch 'protocol_description',
              to: 'my_modules#update_protocol_description',
              as: 'update_protocol_description'
        get 'protocols' # Protocols view for single module
        get 'results' # Results view for single module
        # get 'samples' # Samples view for single module
        # Repository view for single module
        get 'repository/:repository_id',
            to: 'my_modules#repository',
            as: :repository
        post 'repository_index/:repository_id',
             to: 'my_modules#repository_index',
             as: :repository_index
        post 'assign_repository_records_modal/:repository_id',
            to: 'my_modules#assign_repository_records_modal',
            as: :assign_repository_records_modal
        post 'assign_repository_records/:repository_id',
             to: 'my_modules#assign_repository_records',
             as: :assign_repository_records
        post 'unassign_repository_records_modal/:repository_id',
            to: 'my_modules#unassign_repository_records_modal',
            as: :unassign_repository_records_modal
        post 'unassign_repository_records/:repository_id',
            to: 'my_modules#unassign_repository_records',
            as: :unassign_repository_records
        get 'unshared_inventory/:inventory_id',
            to: 'my_modules#unshared_inventory',
            as: :unshared_inventory
        get 'archive' # Archive view for single module
        get 'complete_my_module'
        post 'toggle_task_state'
        get 'repositories_dropdown',
            to: 'my_modules#repositories_dropdown',
            as: :repositories_dropdown
        get 'repositories_dropdown/:repository_id',
            to: 'my_modules#repositories_dropdown',
            as: :repositories_dropdown_repository_tab
        # Renders sample datatable for single module (ajax action)
        # post 'samples_index'
        # post :assign_samples,
        #      constraints: CommitParamRouting.new(
        #        MyModulesController::ASSIGN_SAMPLES
        #      ),
        #      action: :assign_samples
        # post :assign_samples,
        #      constraints: CommitParamRouting.new(
        #        MyModulesController::UNASSIGN_SAMPLES
        #      ),
        #      action: :unassign_samples
        # post :assign_samples,
        #      constraints: CommitParamRouting.new(
        #        MyModulesController::DELETE_SAMPLES
        #      ),
        #      action: :delete_samples
      end

      # Those routes are defined outside of member block
      # to preserve original id parameters in URL.
      get 'tags/edit', to: 'my_module_tags#index_edit'
      get 'users/edit', to: 'user_my_modules#index_edit'
    end

    resources :steps, only: [:edit, :update, :destroy, :show] do
      resources :step_comments,
                path: '/comments',
                only: [:create, :index, :edit, :update, :destroy]
      member do
        post 'checklistitem_state'
        post 'toggle_step_state'
        get 'move_down'
        get 'move_up'
        post 'update_view_state'
      end
    end

    # System notifications routes
    resources :system_notifications, only: %i(index show) do
      collection do
        post 'mark_as_seen'
        get 'unseen_counter'
      end
      member do
        post 'mark_as_read'
      end
    end

    # tinyMCE image uploader endpoint
    resources :tiny_mce_assets, only: [:create] do
      member do
        get :download
        get :marvinjs, to: 'tiny_mce_assets#marvinjs_show'
        put :marvinjs, to: 'tiny_mce_assets#marvinjs_update'
      end
      collection do
        post :marvinjs, to: 'tiny_mce_assets#marvinjs_create'
      end
    end

    resources :results, only: [:update, :destroy] do
      resources :result_comments,
                path: '/comments',
                only: [:create, :index, :edit, :update, :destroy]
    end

    # resources :samples, only: [:edit, :update, :destroy]
    # get 'samples/:id', to: 'samples#show'

    resources :result_texts, only: [:edit, :update, :destroy]
    get 'result_texts/:id/download' => 'result_texts#download',
      as: :result_text_download
    resources :result_assets, only: [:edit, :update, :destroy]
    resources :result_tables, only: [:edit, :update, :destroy]
    get 'result_tables/:id/download' => 'result_tables#download',
      as: :result_table_download

    resources :protocols, only: [:index, :edit, :create] do
      resources :steps, only: [:new, :create]
      member do
        get 'linked_children', to: 'protocols#linked_children'
        post 'linked_children_datatable',
             to: 'protocols#linked_children_datatable'
        get 'preview', to: 'protocols#preview'
        patch 'description', to: 'protocols#update_description'
        put 'name', to: 'protocols#update_name'
        put 'authors', to: 'protocols#update_authors'
        patch 'keywords', to: 'protocols#update_keywords'
        post 'clone', to: 'protocols#clone'
        get 'unlink_modal', to: 'protocols#unlink_modal'
        post 'unlink', to: 'protocols#unlink'
        get 'revert_modal', to: 'protocols#revert_modal'
        post 'revert', to: 'protocols#revert'
        get 'update_parent_modal', to: 'protocols#update_parent_modal'
        post 'update_parent', to: 'protocols#update_parent'
        get 'update_from_parent_modal', to: 'protocols#update_from_parent_modal'
        post 'update_from_parent', to: 'protocols#update_from_parent'
        post 'load_from_repository_datatable',
             to: 'protocols#load_from_repository_datatable'
        get 'load_from_repository_modal',
            to: 'protocols#load_from_repository_modal'
        post 'load_from_repository', to: 'protocols#load_from_repository'
        post 'load_from_file', to: 'protocols#load_from_file'

        get 'copy_to_repository_modal', to: 'protocols#copy_to_repository_modal'
        post 'copy_to_repository', to: 'protocols#copy_to_repository'
        get 'protocol_status_bar', to: 'protocols#protocol_status_bar'
        get 'updated_at_label', to: 'protocols#updated_at_label'
        get 'edit_name_modal', to: 'protocols#edit_name_modal'
        get 'edit_keywords_modal', to: 'protocols#edit_keywords_modal'
        get 'edit_authors_modal', to: 'protocols#edit_authors_modal'
        get 'edit_description_modal', to: 'protocols#edit_description_modal'
      end
      collection do
        get 'create_new_modal', to: 'protocols#create_new_modal'
        post 'datatable', to: 'protocols#datatable'
        post 'make_private', to: 'protocols#make_private'
        post 'publish', to: 'protocols#publish'
        post 'archive', to: 'protocols#archive'
        post 'restore', to: 'protocols#restore'
        post 'import', to: 'protocols#import'
        post 'protocolsio_import_create',
             to: 'protocols#protocolsio_import_create'
        post 'protocolsio_import_save', to: 'protocols#protocolsio_import_save'
        get 'export', to: 'protocols#export'
        get 'recent_protocols'
      end
    end

    resources :repositories do
      post 'repository_index',
           to: 'repository_rows#index',
           as: 'table_index',
           defaults: { format: 'json' }
      member do
        get :load_table
      end
      # Save repository table state
      post 'state_save',
           to: 'user_repositories#save_table_state',
           as: 'save_table_state',
           defaults: { format: 'json' }
      # Load repository table state
      post 'state_load',
           to: 'user_repositories#load_table_state',
           as: 'load_table_state',
           defaults: { format: 'json' }
      # Delete records from repository
      post 'delete_records',
           to: 'repository_rows#delete_records',
           as: 'delete_records',
           defaults: { format: 'json' }
      post 'copy_records',
           to: 'repository_rows#copy_records',
           defaults: { format: 'json' }
      get 'repository_columns/:id/destroy_html',
          to: 'repository_columns#destroy_html',
          as: 'columns_destroy_html'
      get 'index_html',
          to: 'repository_columns#index_html',
          as: 'columns_index_html',
          defaults: { format: 'json' }
      get 'create_html',
          to: 'repository_columns#create_html',
          as: 'columns_create_html',
          defaults: { format: 'json' }
      get 'available_columns',
          to: 'repository_columns#available_columns',
          as: 'available_columns',
          defaults: { format: 'json' }

      resources :repository_columns, only: %i(create edit update destroy)
      resources :repository_rows, only: %i(create edit update)
      member do
        post 'parse_sheet', defaults: { format: 'json' }
        post 'import_records'
      end
      namespace :repository_columns do
        resources :text_columns, only: %i(create update destroy)
        resources :number_columns, only: %i(create update destroy)
        resources :asset_columns, only: %i(create update destroy)
        resources :date_columns, only: %i(create update destroy)
        resources :date_time_columns, only: %i(create update destroy)
        resources :list_columns, only: %i(create update destroy) do
          member do
            get 'items'
          end
        end
        resources :checklist_columns, only: %i(create update destroy) do
          member do
            get 'items'
          end
        end
        resources :status_columns, only: %i(create update destroy) do
          member do
            get 'items'
          end
        end
      end
    end

    post 'available_rows', to: 'repository_rows#available_rows',
                           defaults: { format: 'json' }

    get 'repository_rows/:id', to: 'repository_rows#show',
                               as: :repository_row,
                               defaults: { format: 'json' }

    get 'search' => 'search#index'
    get 'search/new' => 'search#new', as: :new_search

    # We cannot use 'resources :assets' because assets is a reserved route
    # in Rails (assets pipeline) and causes funky behavior
    get 'files/:id/preview',
        to: 'assets#file_preview',
        as: 'asset_file_preview'
    get 'files/:id/preview', to: 'assets#preview', as: 'preview_asset'
    get 'files/:id/view', to: 'assets#view', as: 'view_asset'
    get 'files/:id/file_url', to: 'assets#file_url', as: 'asset_file_url'
    get 'files/:id/edit', to: 'assets#edit', as: 'edit_asset'
    post 'files/:id/update_image', to: 'assets#update_image',
                                   as: 'update_asset_image'
    post 'files/create_wopi_file',
         to: 'assets#create_wopi_file',
         as: 'create_wopi_file'
    post 'files/:id/start_edit_image', to: 'assets#create_start_edit_image_activity', as: 'start_edit_image'

    devise_scope :user do
      get 'avatar/:id/:style' => 'users/registrations#avatar', as: 'avatar'
      get 'users/auth_token_sign_in' => 'users/sessions#auth_token_create'
      get 'users/sign_up_provider' => 'users/registrations#new_with_provider'
      post 'users/complete_sign_up_provider' =>
           'users/registrations#create_with_provider'
    end

    namespace :api, defaults: { format: 'json' } do
      get 'health', to: 'api#health'
      get 'status', to: 'api#status'
      if Rails.configuration.x.core_api_v1_enabled
        namespace :v1 do
          resources :teams, only: %i(index show) do
            resources :inventories,
                      only: %i(index create show update destroy) do
              resources :inventory_columns,
                        only: %i(index create show update destroy),
                        path: 'columns',
                        as: :columns do
                resources :inventory_list_items,
                          only: %i(index create show update destroy),
                          path: 'list_items',
                          as: :list_items
                resources :inventory_status_items,
                          only: %i(index create show update destroy),
                          path: 'status_items',
                          as: :status_items
              end
              resources :inventory_items,
                        only: %i(index create show update destroy),
                        path: 'items',
                        as: :items do
                resources :inventory_cells,
                          only: %i(index create show update destroy),
                          path: 'cells',
                          as: :cells
              end
            end
            resources :projects, only: %i(index show) do
              resources :user_projects, only: %i(index show),
                path: 'users', as: :users
              resources :project_comments, only: %i(index show),
                path: 'comments', as: :comments
              get 'activities', to: 'projects#activities'
              resources :reports, only: %i(index show),
                path: 'reports', as: :reports
              resources :experiments, only: %i(index show) do
                resources :task_groups, only: %i(index show)
                resources :connections, only: %i(index show)
                resources :tasks, only: %i(index show create) do
                  resources :task_inventory_items, only: %i(index show),
                            path: 'items',
                            as: :items
                  resources :task_users, only: %i(index show),
                            path: 'users',
                            as: :users
                  resources :task_tags, only: %i(index show),
                            path: 'tags',
                            as: :tags
                  resources :protocols, only: %i(index) do
                    resources :steps, only: %i(index show create) do
                      resources :assets, only: %i(index show create), path: 'attachments'
                    end
                  end
                  resources :results, only: %i(index create show update)
                  get 'activities', to: 'tasks#activities'
                end
              end
            end
          end
          resources :users, only: %i(show) do
            resources :user_identities,
                      only: %i(index create show update destroy),
                      path: 'identities',
                      as: :identities
          end
        end
      end
    end
  end

  resources :global_activities, only: [:index] do
    collection do
      get :project_filter
      get :experiment_filter
      get :my_module_filter
      get :inventory_filter
      get :inventory_item_filter
      get :report_filter
      get :protocol_filter
      get :team_filter
      get :user_filter
    end
  end

  resources :marvin_js_assets, only: %i(create update destroy show) do
    collection do
      get :team_sketches
    end
    member do
      post :start_editing
    end
  end

  post 'global_activities', to: 'global_activities#index'

  constraints WopiSubdomain do
    # Office integration
    get 'wopi/files/:id/contents', to: 'wopi#file_contents_get_endpoint'
    post 'wopi/files/:id/contents', to: 'wopi#file_contents_post_endpoint'
    get 'wopi/files/:id', to: 'wopi#file_get_endpoint', as: 'wopi_rest_endpoint'
    post 'wopi/files/:id', to: 'wopi#post_file_endpoint'
  end
end
