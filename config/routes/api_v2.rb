# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

namespace :v2, module: 'v1' do
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
        resources :inventory_item_relationships, only: %i(create destroy)
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
          resources :protocols, only: %i(index show)

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

namespace :v2 do
  resources :teams do
    resources :projects do
      resources :experiments do
        resources :tasks do
          resources :results, only: %i(index create show update destroy) do
            resources :result_assets, only: %i(index show create update destroy), path: 'assets'
            resources :result_tables, only: %i(index show create update destroy), path: 'tables'
            resources :result_texts, only: %i(index show create update destroy)
          end

          resources :protocols, only: :show do
            resources :steps, except: %i(new edit) do
              scope module: 'step_elements' do
                resources :assets, except: %i(new edit)
                resources :checklists, except: %i(new edit) do
                  resources :checklist_items, except: %i(new edit), as: :items
                end
                resources :tables, except: %i(new edit)
                resources :texts, except: %i(new edit)
              end
            end
          end
        end
      end
    end
  end
end

# rubocop:enable Metrics/BlockLength
