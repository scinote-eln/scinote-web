Rails.application.routes.draw do
  use_doorkeeper do
    skip_controllers :applications, :authorized_applications, :token_info
  end

  post 'access_tokens/revoke', to: 'doorkeeper/access_tokens#revoke'

  # Addons

  def draw(routes_name)
    instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
  end

  constraints UserSubdomain do
    devise_for :users, controllers: { registrations: 'users/registrations',
                                      sessions: 'users/sessions',
                                      invitations: 'users/invitations',
                                      confirmations: 'users/confirmations',
                                      omniauth_callbacks: 'users/omniauth_callbacks',
                                      passwords: 'users/passwords' }

    root 'dashboards#show'

    resources :navigations, only: [] do
      collection do
        get :top_menu
        post :navigator_state
      end
    end

    resources :activities, only: [:index]

    get '/jobs/:id/status', to: 'active_jobs#status'

    get 'forbidden', to: 'application#forbidden', as: 'forbidden'
    get 'not_found', to: 'application#not_found', as: 'not_found'
    get 'unprocessable_entity', to: 'application#respond_422', as: 'unprocessable_entity'

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

    resources :label_templates, only: %i(index show update create) do
      member do
        post :set_default
      end
      collection do
        post :duplicate
        post :delete
        get :datatable
        get :template_tags
        get :zpl_preview
        post :sync_fluics_templates
        get :actions_toolbar
      end
    end

    resources :label_printers, except: :show, path: 'users/settings/account/addons/label_printers' do
      post :create_fluics, on: :collection
    end

    get 'users/settings/account/addons/label_printers/settings_zebra',
        to: 'label_printers#index_zebra',
        as: 'zebra_settings'

    resources :label_printers, only: [] do
      post :print, on: :member
      get :update_progress_modal, on: :member
    end

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

    namespace :users do
      namespace :settings do
        resources :teams, only: [] do
          member do
            post :switch
          end
        end
        resources :webhooks, only: %i(index create update destroy) do
          collection do
            post :destroy_filter
            get :filter_info
          end
        end
      end
    end


    # Invite users
    devise_scope :user do
      post '/invite',
           to: 'users/invitations#invite_users',
           as: 'invite_users'
      get '/invitable_teams',
          to: 'users/invitations#invitable_teams',
          as: 'invitable_teams'
    end

    resources :user_notifications, only: :index do
      collection do
        get :unseen_counter
      end
    end

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
          post 'archive', to: 'repositories#archive',
              defaults: { format: 'json' }
          post 'restore', to: 'repositories#restore',
              defaults: { format: 'json' }
          get 'create_modal', to: 'repositories#create_modal',
              defaults: { format: 'json' }
          get 'actions_toolbar'
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
        post 'hide_reminders', to: 'repositories#hide_reminders'

        resources :team_repositories, only: %i(destroy) do
          collection do
            post 'update'
          end
        end
      end

      member do
        post 'parse_sheet', defaults: { format: 'json' }
        post 'export_repository', to: 'repositories#export_repository'
        post 'export_projects'
        get 'sidebar'
        get 'export_projects_modal'
        # Used for atwho (smart annotations)
        get 'atwho_users', to: 'at_who#users'
        get 'atwho_menu', to: 'at_who#menu'
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

    resources :reports, only: [:index, :new, :create, :update] do
      member do
        get :document_preview
        get :save_pdf_to_inventory_modal, defaults: { format: 'json' }
        post :save_pdf_to_inventory_item, defaults: { format: 'json' }
      end
      collection do
        get :project_contents
        get 'actions_toolbar'
      end
    end
    get 'reports/datatable', to: 'reports#datatable'
    get 'reports/new_template_values', to: 'reports#new_template_values', defaults: { format: 'json' }
    post 'reports/available_repositories', to: 'reports#available_repositories',
                                           defaults: { format: 'json' }
    post 'available_asset_type_columns',
          to: 'repository_columns#available_asset_type_columns',
          defaults: { format: 'json' }
    post 'reports/destroy', to: 'reports#destroy'

    resource :dashboard, only: :show do
      resource :current_tasks, module: 'dashboard', only: :show do
        get :project_filter
        get :experiment_filter
      end

      namespace :quick_start, module: :dashboard, controller: :quick_start do
        get :project_filter
        get :experiment_filter
        post :create_task
      end

      resource :calendar, module: 'dashboard', only: [:show] do
        get :day
      end

      resource :recent_works, module: 'dashboard', only: [:show]
    end

    namespace :access_permissions do
      resources :projects, defaults: { format: 'json' } do
        put :update_default_public_user_role, on: :member
      end

      resources :protocols, defaults: { format: 'json' } do
        put :update_default_public_user_role, on: :member
      end

      resources :experiments, only: %i(show update edit)
      resources :my_modules, only: %i(show update edit)
    end

    namespace :navigator do
      resources :project_folders, only: %i(show) do
        member do
          get :tree
        end
      end

      resources :projects, only: %i(show index) do
        member do
          get :tree
        end
      end

      resources :experiments, only: %i(show) do
        member do
          get :tree
        end
      end

      resources :my_modules, only: %i(show) do
        member do
          get :tree
        end
      end
    end

    resources :projects, except: [:destroy] do
      resources :project_comments,
                path: '/comments',
                only: %i(create index update destroy)
      # Activities popup (JSON) for individual project in projects index,
      # as well as all activities page for single project (HTML)
      resources :project_activities, path: '/activities', only: [:index]
      resources :tags, only: [:create, :update, :destroy]
      post :create_tag

      resources :reports,
                path: '/reports',
                only: %i(edit update create) do
        member do
          post 'generate_pdf', to: 'reports#generate_pdf'
          post 'generate_docx', to: 'reports#generate_docx'
          get 'status', to: 'reports#status', format: %w(json)
        end

        collection do
          get 'new', to: 'reports#new'
        end
      end
      resources :experiments, only: %i(new create), defaults: { format: 'json' } do
        collection do
          post 'archive_group' # archive group of experiments
          post 'restore_group' # restore group of experiments
        end
      end
      member do
        # Notifications popup for individual project in projects index
        get 'notifications'
        get 'permissions'
        get 'experiments_cards'
        get 'sidebar'
        get 'actions_dropdown'
        put 'view_type'
      end

      collection do
        get 'project_filter'
        get 'cards', to: 'projects#cards'
        get 'users_filter'
        post 'archive_group'
        post 'restore_group'
        put 'view_type', to: 'teams#view_type'
        get 'actions_toolbar'
      end
    end

    resources :project_folders, only: %i(create new update edit) do
      get 'cards', to: 'projects#cards'

      collection do
        post 'move_to', to: 'project_folders#move_to', defaults: { format: 'json' }
        get 'move_to_modal', to: 'project_folders#move_to_modal', defaults: { format: 'json' }
        post 'destroy', to: 'project_folders#destroy', as: 'destroy', defaults: { format: 'json' }
        get 'destroy_modal', to: 'project_folders#destroy_modal', defaults: { format: 'json' }
      end
    end
    get 'project_folders/:project_folder_id', to: 'projects#index', as: :project_folder_projects

    resources :experiments, only: %i(show edit update) do
      collection do
        get 'experiment_filter'
        get 'edit', action: :edit
        get 'clone_modal', action: :clone_modal
        get 'move_modal', action: :move_modal
        get 'actions_toolbar'
      end
      member do
        get 'permissions'
        get 'actions_dropdown'
        put :view_type
        get :table
        get :load_table
        get :move_modules_modal
        post :move_modules
        get :my_modules
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
        post 'archive' # archive experiment
        get 'clone_modal' # return modal with clone options
        post 'clone' # clone experiment
        get 'move_modal' # return modal with move options
        post 'move' # move experiment
        get 'fetch_workflow_img' # Get updated workflow img
        get 'modules/new', to: 'my_modules#new'
        post 'modules', to: 'my_modules#create'
        post 'restore_my_modules', to: 'my_modules#restore_group'
        get 'sidebar'
        get :assigned_users_to_tasks
        post :archive_my_modules
        post :batch_clone_my_modules
        get :search_tags
      end
    end

    # Show action is a popup (JSON) for individual module in full-zoom canvas,
    # as well as 'module info' page for single module (HTML)
    resources :my_modules, path: '/modules', only: [:show, :update] do
      post 'save_table_state', on: :collection, defaults: { format: 'json' }
      get 'module_filter', to: 'my_modules#my_module_filter', on: :collection, defaults: { format: 'json' }

      collection do
        get 'actions_toolbar'
      end

      member do
        get :permissions
        get :actions_dropdown
        get :provisioning_status
      end
      resources :my_module_tags, path: '/tags', only: [:index, :create, :destroy] do
        collection do
          get :search_tags
        end
        member do
          post :destroy_by_tag_id
        end
      end
      resources :user_my_modules, path: '/users', only: %i(index create destroy) do
        collection do
          get :designated_users
        end
        member do
          get :search
        end
      end

      resource :status_flow, controller: :my_module_status_flow, only: :show

      resources :my_module_comments,
                path: '/comments',
                only: %i(create index update destroy)

      get :repositories_dropdown_list, controller: :my_module_repositories
      get :repositories_list_html, controller: :my_module_repositories

      resources :repositories, controller: :my_module_repositories, only: %i(update create) do
        member do
          get :full_view_table
          post :index_dt
          post :export_repository
          get :assign_repository_records_modal, as: :assign_modal
          get :update_repository_records_modal, as: :update_modal
          get :consume_modal
          post :update_consumption
        end
      end

      resources :repository_snapshots, controller: :my_module_repository_snapshots, only: %i(destroy show) do
        member do
          get :full_view_table
          post :index_dt
          post :export_repository_snapshot
          get :status
        end

        collection do
          get ':repository_id/full_view_sidebar',
              to: 'my_module_repository_snapshots#full_view_sidebar',
              as: :full_view_sidebar
          post ':repository_id', to: 'my_module_repository_snapshots#create', as: ''
        end
      end

      post :select_default_snapshot, to: 'my_module_repository_snapshots#select'

      resources :result_texts, only: [:new, :create]
      resources :result_assets, only: [:new, :create]
      resources :result_tables, only: [:new, :create]
      member do
        # AJAX popup accessed from full-zoom canvas for single module,
        # as well as full activities view (HTML) for single module
        get 'description'
        get 'canvas_dropdown_menu'
        get 'activities'
        post 'activities'
        get 'activities_tab' # Activities in tab view for single module
        get 'due_date'
        get 'status_state'
        patch 'description',
              to: 'my_modules#update_description',
              as: 'update_description'
        patch 'protocol_description',
              to: 'my_modules#update_protocol_description',
              as: 'update_protocol_description'
        patch 'state', to: 'my_modules#update_state', as: 'update_state'
        get 'protocols' # Protocols view for single module
        get 'protocol', to: 'my_modules#protocol', as: 'protocol'
        patch 'protocol', to: 'my_modules#update_protocol', as: 'update_protocol'
        get 'results' # Results view for single module
        get 'archive' # Archive view for single module
      end

      # Those routes are defined outside of member block
      # to preserve original id parameters in URL.
      get 'tags/edit', to: 'my_module_tags#index_edit'
      get 'users/edit', to: 'user_my_modules#index_edit'
    end

    resources :steps, only: %i(index update destroy show) do
      resources :step_orderable_elements do
        post :reorder, on: :collection
      end
      resources :step_comments,
                path: '/comments',
                only: %i(create index update destroy)
      resources :tables, controller: 'step_elements/tables', only: %i(create destroy update) do
        member do
          post :duplicate
        end
      end
      resources :texts, controller: 'step_elements/texts', only: %i(create destroy update) do
        member do
          post :duplicate
        end
      end
      resources :checklists, controller: 'step_elements/checklists', only: %i(create destroy update) do
        member do
          post :duplicate
        end
        resources :checklist_items, controller: 'step_elements/checklist_items', only: %i(create update destroy) do
          patch :toggle, on: :member
          post :reorder, on: :collection
        end
      end
      member do
        get 'elements'
        get 'attachments'
        post 'upload_attachment'
        post 'toggle_step_state'
        post 'update_view_state'
        post 'update_asset_view_mode'
        post 'duplicate'
      end
    end

    # System notifications routes
    resources :system_notifications, only: %i(show) do
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
                only: %i(create index update destroy)
    end

    resources :result_texts, only: [:edit, :update, :destroy]
    get 'result_texts/:id/download' => 'result_texts#download',
      as: :result_text_download
    resources :result_assets, only: [:edit, :update, :destroy]
    resources :result_tables, only: [:edit, :update, :destroy]
    get 'result_tables/:id/download' => 'result_tables#download',
      as: :result_table_download

    resources :protocols, only: %i(index show edit create update) do
      resources :steps, only: [:create] do
        post :reorder, on: :collection
      end
      member do
        post :publish
        post :destroy_draft
        post :save_as_draft
        get 'version_comment', to: 'protocols#version_comment'
        get 'print', to: 'protocols#print'
        get 'linked_children', to: 'protocols#linked_children'
        post 'linked_children_datatable',
             to: 'protocols#linked_children_datatable'
        get 'versions_modal', to: 'protocols#versions_modal'
        patch 'description', to: 'protocols#update_description'
        put 'name', to: 'protocols#update_name'
        patch 'authors', to: 'protocols#update_authors'
        patch 'keywords', to: 'protocols#update_keywords'
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
        post 'delete_steps'
        get :permissions
        put :update_version_comment
      end
      collection do
        post 'datatable', to: 'protocols#datatable'
        post 'archive', to: 'protocols#archive'
        post 'restore', to: 'protocols#restore'
        post 'clone', to: 'protocols#clone'
        post 'import', to: 'protocols#import'
        post 'protocolsio_import_create',
             to: 'protocols#protocolsio_import_create'
        post 'protocolsio_import_save', to: 'protocols#protocolsio_import_save'
        get 'export', to: 'protocols#export'
        get 'protocolsio', to: 'protocols#protocolsio_index'
        get 'actions_toolbar', to: 'protocols#actions_toolbar'
      end
    end

    resources :comments, only: %i(index create update destroy)

    resources :repository_rows, only: %i() do
      member do
        get :rows_to_print
        post :print
        get :print_zpl
        post :validate_label_template_columns
      end

      collection do
        get :actions_toolbar
      end
    end

    resources :repositories do
      post 'repository_index',
           to: 'repository_rows#index',
           as: 'table_index',
           defaults: { format: 'json' }
      member do
        get :assigned_my_modules
        get :repository_users
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
      post 'archive_records',
           to: 'repository_rows#archive_records',
           defaults: { format: 'json' }
      post 'restore_records',
           to: 'repository_rows#restore_records',
           defaults: { format: 'json' }
      get 'repository_columns/:id/destroy_html',
          to: 'repository_columns#destroy_html',
          as: 'columns_destroy_html'
      get 'available_columns',
          to: 'repository_columns#available_columns',
          as: 'available_columns',
          defaults: { format: 'json' }
      get :table_toolbar
      get :status

      resources :repository_columns, only: %i(index new edit destroy) do
        collection do
          get :describe_all
        end
      end
      resources :repository_table_filters, only: %i(index show create update destroy)
      resources :repository_rows, only: %i(create show update) do
        member do
          get :assigned_task_list
          get :active_reminder_repository_cells
        end
        member do
          get 'repository_stock_value/new', to: 'repository_stock_values#new', as: 'new_repository_stock'
          get 'repository_stock_value/edit', to: 'repository_stock_values#edit', as: 'edit_repository_stock'
          post 'repository_stock_value', to: 'repository_stock_values#create_or_update', as: 'update_repository_stock'
        end
        resources :repository_stock_values, only: %i(new create edit update)
        resources :repository_cells, only: :hide_reminder do
          post :hide_reminder, to: 'hidden_repository_cell_reminders#create'
        end
      end

      collection do
        get :sidebar
        post 'available_rows', to: 'repository_rows#available_rows', defaults: { format: 'json' }
      end

      member do
        post 'parse_sheet', defaults: { format: 'json' }
        post 'import_records'
      end
      namespace :repository_columns do
        resources :text_columns, only: %i(create update)
        resources :number_columns, only: %i(create update)
        resources :asset_columns, only: %i(create update)
        resources :date_columns, only: %i(create update)
        resources :date_time_columns, only: %i(create update)
        resources :list_columns, only: %i(create update) do
          member do
            get 'items'
          end
        end
        resources :checklist_columns, only: %i(create update) do
          member do
            get 'items'
          end
        end
        resources :stock_columns, only: %i(create update) do
          member do
            get 'items'
          end
        end
        resources :status_columns, only: %i(create update) do
          member do
            get 'items'
          end
        end
      end
    end

    resources :connected_devices, controller: 'users/connected_devices', only: %i(destroy)

    get 'search' => 'search#index'
    get 'search/new' => 'search#new', as: :new_search

    # We cannot use 'resources :assets' because assets is a reserved route
    # in Rails (assets pipeline) and causes funky behavior
    get 'files/:id/preview',
        to: 'assets#file_preview',
        as: 'asset_file_preview'
    get 'files/:id/pdf_preview', to: 'assets#pdf_preview', as: 'asset_pdf_preview'
    get 'files/:id/view', to: 'assets#view', as: 'view_asset'
    get 'files/:id/file_url', to: 'assets#file_url', as: 'asset_file_url'
    get 'files/:id/download', to: 'assets#download', as: 'asset_download'
    get 'files/:id/edit', to: 'assets#edit', as: 'edit_asset'
    patch 'files/:id/toggle_view_mode', to: 'assets#toggle_view_mode', as: 'toggle_view_mode'
    get 'files/:id/load_asset', to: 'assets#load_asset', as: 'load_asset'
    post 'files/:id/update_image', to: 'assets#update_image',
                                   as: 'update_asset_image'
    delete 'files/:id/', to: 'assets#destroy', as: 'asset_destroy'
    post 'files/create_wopi_file',
         to: 'assets#create_wopi_file',
         as: 'create_wopi_file'
    post 'files/:id/start_edit_image', to: 'assets#create_start_edit_image_activity', as: 'start_edit_image'

    devise_scope :user do
      get 'avatar/:id/:style' => 'users/registrations#avatar', as: 'avatar'
      get 'users/sign_up_provider' => 'users/registrations#new_with_provider'
      get 'users/two_factor_recovery' => 'users/sessions#two_factor_recovery'
      get 'users/two_factor_auth' => 'users/sessions#two_factor_auth'
      get 'users/expire_in' => 'users/sessions#expire_in'
      post 'users/revive_session' => 'users/sessions#revive_session'
      post 'users/authenticate_with_two_factor' => 'users/sessions#authenticate_with_two_factor'
      post 'users/authenticate_with_recovery_code' => 'users/sessions#authenticate_with_recovery_code'
      post 'users/complete_sign_up_provider' => 'users/registrations#create_with_provider'

      post 'users/2fa_enable' => 'users/registrations#two_factor_enable'
      post 'users/2fa_disable' => 'users/registrations#two_factor_disable'
      get 'users/2fa_qr_code' => 'users/registrations#two_factor_qr_code'
    end

    namespace :api, defaults: { format: 'json' } do
      get 'health', to: 'api#health'
      get 'status', to: 'api#status'
      namespace :service do
        post 'projects_json_export', to: 'projects_json_export#projects_json_export'
        resources :teams, only: [] do
          post 'clone_experiment' => 'experiments#clone'

          resources :protocols, only: [] do
            post 'reorder_steps' => 'protocols#reorder_steps'
          end

          resources :steps, only: [] do
            post 'reorder_elements' => 'steps#reorder_elements'
          end
        end
      end
      if Rails.configuration.x.core_api_v1_enabled
        namespace :v1 do
          resources :teams, only: %i(index show) do
            resources :inventories, only: %i(index create show update destroy) do
              resources :inventory_columns,
                        only: %i(index create show update destroy),
                        path: 'columns',
                        as: :columns do
                resources :inventory_list_items,
                          only: %i(index create show update destroy),
                          path: 'list_items',
                          as: :list_items
                resources :inventory_checklist_items,
                          only: %i(index create show update destroy),
                          path: 'checklist_items',
                          as: :checklist_items
                resources :inventory_status_items,
                          only: %i(index create show update destroy),
                          path: 'status_items',
                          as: :status_items
                resources :inventory_stock_unit_items,
                          only: %i(index create show update destroy),
                          path: 'stock_unit_items',
                          as: :stock_unit_items
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
            resources :projects, only: %i(index show create update) do
              resources :user_assignments,
                        only: %i(index show create update destroy),
                        controller: :project_user_assignments,
                        path: 'users',
                        as: :users
              resources :project_comments, only: %i(index show), path: 'comments', as: :comments
              get 'activities', to: 'projects#activities'
              resources :reports, only: %i(index show), path: 'reports', as: :reports
              resources :experiments, only: %i(index show create update) do
                resources :user_assignments,
                          only: %i(index show update),
                          controller: :experiment_user_assignments
                resources :task_groups, only: %i(index show)
                resources :connections, only: %i(index show create destroy)
                resources :tasks, only: %i(index show create update) do
                  resources :user_assignments,
                            only: %i(index show update),
                            controller: :task_user_assignments
                  resources :task_inventory_items, only: %i(index show update),
                            path: 'items',
                            as: :items
                  resources :task_users, only: %i(index show),
                            path: 'users',
                            as: :users
                  resources :task_tags, only: %i(index show),
                            path: 'tags',
                            as: :tags
                  resources :task_assignments, only: %i(index create destroy),
                            path: 'task_assignments',
                            as: :task_assignments
                  resources :protocols, only: %i(index show) do
                    resources :steps, only: %i(index show create update destroy) do
                      resources :assets, only: %i(index show create), path: 'attachments'
                      resources :checklists, only: %i(index show create update destroy), path: 'checklists' do
                        resources :checklist_items,
                                  only: %i(index show create update destroy),
                                  as: :items,
                                  path: 'items'
                      end
                      resources :tables, only: %i(index show create update destroy), path: 'tables'
                      resources :step_texts, only: %i(index show create update destroy), path: 'step_texts'
                    end
                  end
                  resources :results, only: %i(index create show update)
                  get 'activities', to: 'tasks#activities'
                end
              end
            end
            resources :project_folders, only: %i(index show create update)
            resources :users, only: %i(index)
            resources :protocol_templates, only: %i(index show)
          end
          resources :users, only: %i(show) do
            resources :user_identities,
                      only: %i(index create show update destroy),
                      path: 'identities',
                      as: :identities
          end

          resources :user_roles, only: :index
          resources :workflows, only: %i(index show) do
            resources :workflow_statuses, path: :statuses, only: %i(index)
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
      post :save_activity_filter
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

  resources :bio_eddie_assets, only: %i(create update) do
    collection do
      get :license
    end
    member do
      post :start_editing
    end
  end

  resources :bmt_filters, only: %i(index create destroy)

  match '/marvin4js-license.cxl', to: 'bio_eddie_assets#license', via: :get

  match 'biomolecule_toolkit/*path', to: 'bio_eddie_assets#bmt_request',
                                     via: %i(get post put delete),
                                     defaults: { format: 'json' },
                                     as: 'bmt_request'

  post 'global_activities', to: 'global_activities#index'

  constraints WopiSubdomain do
    # Office integration
    get 'wopi/files/:id/contents', to: 'wopi#file_contents_get_endpoint'
    post 'wopi/files/:id/contents', to: 'wopi#file_contents_post_endpoint'
    get 'wopi/files/:id', to: 'wopi#file_get_endpoint', as: 'wopi_rest_endpoint'
    post 'wopi/files/:id', to: 'wopi#post_file_endpoint'
  end
end
