FactoryBot.define do
  factory :user_role do
    factory :owner_role do
      name { I18n.t('user_roles.predefined.owner') }
      permissions { PredefinedRoles::OWNER_PERMISSIONS }
      predefined { true }
    end

    factory :normal_user_role do
      name { I18n.t('user_roles.predefined.normal_user') }
      permissions { PredefinedRoles::NORMAL_USER_PERMISSIONS }
      predefined { true }
    end

    factory :technician_role do
      name { I18n.t('user_roles.predefined.technician') }
      permissions { PredefinedRoles::TECHNICIAN_PERMISSIONS }
      predefined { true }
    end

    factory :viewer_role do
      name { I18n.t('user_roles.predefined.viewer') }
      permissions { PredefinedRoles::VIEWER_PERMISSIONS }
      predefined { true }
    end
  end
end
