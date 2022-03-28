# frozen_string_literal: true

Canaid::Permissions.register_for(MyModuleRepositoryRow) do
  can :update_stock_my_module_repository_row_stock_consumption do |user, my_module_repository_row|
    repository_row = my_module_repository_row.repository_row
    repository = repository_row.repository

    can_update_my_module_stock_consumption?(user, my_module_repository_row.my_module) &&
      !repository_row.archived? &&
      !repository.archived?
  end
end
