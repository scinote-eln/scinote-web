# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

namespace :v2 do
  resources :teams, only: [] do
    resources :user_groups, only: %i(index)

    resources :projects, only: [] do
      resources :user_group_assignments,
                only: %i(index show create update destroy),
                controller: :project_user_group_assignments
      resources :team_assignments,
                only: %i(index show create update destroy),
                controller: :project_team_assignments
      resources :experiments, only: [] do
        resources :user_group_assignments,
                  only: %i(index show update),
                  controller: :experiment_user_group_assignments
        resources :team_assignments,
                  only: %i(index show update),
                  controller: :experiment_team_assignments
        resources :tasks, only: [] do
          resources :user_group_assignments,
                    only: %i(index show update),
                    controller: :task_user_group_assignments
          resources :team_assignments,
                    only: %i(index show update),
                    controller: :task_team_assignments
          resources :results, only: %i(index create show update destroy) do
            scope module: 'result_elements' do
              resources :assets, except: %i(new edit), path: 'attachments'
              resources :tables, except: %i(new edit), path: 'tables'
              resources :texts, except: %i(new edit)
            end
          end

          resources :protocols, only: [] do
            resources :steps, except: %i(new edit) do
              scope module: 'step_elements' do
                resources :assets, except: %i(new edit), path: 'attachments'
                resources :checklists, except: %i(new edit) do
                  resources :checklist_items, except: %i(new edit), as: :items
                end
                resources :tables, except: %i(new edit)
                resources :texts, except: %i(new edit)
                resources :form_responses, only: %i(index show)
              end
            end
          end
        end
      end
    end

    resources :inventories, only: [] do
      resources :inventory_items,
                path: 'items',
                only: [],
                as: :items do
        resources :child_relationships,
                  only: %i(index show create destroy),
                  controller: :inventory_item_child_relationships
        resources :parent_relationships,
                  only: %i(index show create destroy),
                  controller: :inventory_item_parent_relationships
      end
    end
  end
end

# rubocop:enable Metrics/BlockLength
