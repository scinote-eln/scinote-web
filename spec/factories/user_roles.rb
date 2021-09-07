FactoryBot.define do
  factory :user_role do
    factory :owner_role do
      name { I18n.t('user_roles.predefined.owner') }
      permissions { ProjectPermissions.constants.map { |const| ProjectPermissions.const_get(const) } +
                      ExperimentPermissions.constants.map { |const| ExperimentPermissions.const_get(const) } +
                      MyModulePermissions.constants.map { |const| MyModulePermissions.const_get(const) } }
      predefined { true }
    end

    factory :normal_user_role do
      name { I18n.t('user_roles.predefined.normal_user') }
      permissions {
        [
          ProjectPermissions::READ,
          ProjectPermissions::EXPERIMENTS_CREATE,
          ProjectPermissions::COMMENTS_CREATE,
          ExperimentPermissions::READ,
          ExperimentPermissions::MANAGE,
          ExperimentPermissions::ARCHIVE,
          ExperimentPermissions::RESTORE,
          ExperimentPermissions::CLONE,
          ExperimentPermissions::CREATE_TASKS,
          MyModulePermissions::READ,
          MyModulePermissions::CREATE_COMMENTS,
          MyModulePermissions::ASSIGN_REPOSITORY_ROWS,
          MyModulePermissions::CHANGE_FLOW_STATUS,
          MyModulePermissions::CREATE_REPOSITORY_SNAPSHOT,
          MyModulePermissions::MANAGE_REPOSITORY_SNAPSHOT
        ]
      }
      predefined { true }
    end

    factory :technician_role do
      name { I18n.t('user_roles.predefined.technician') }
      permissions {
        [
          ProjectPermissions::READ,
          ProjectPermissions::COMMENTS_CREATE,
          ExperimentPermissions::READ,
          MyModulePermissions::READ,
          MyModulePermissions::CREATE_COMMENTS,
          MyModulePermissions::ASSIGN_REPOSITORY_ROWS,
          MyModulePermissions::CHANGE_FLOW_STATUS,
          MyModulePermissions::CREATE_REPOSITORY_SNAPSHOT,
          MyModulePermissions::MANAGE_REPOSITORY_SNAPSHOT
        ]
      }
      predefined { true }
    end

    factory :viewer_role do
      name { I18n.t('user_roles.predefined.viewer') }
      permissions {
        [
          ProjectPermissions::READ,
          ExperimentPermissions::READ,
          MyModulePermissions::READ
        ]
      }
      predefined { true }
    end
  end
end
