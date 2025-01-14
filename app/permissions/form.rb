# frozen_string_literal: true

Canaid::Permissions.register_for(Form) do
  %i(manage_form
     clone_form
     publish_form)
    .each do |perm|
    can perm do |_, form|
      form.active?
    end
  end

  can :read_form do |user, form|
    form.permission_granted?(user, FormPermissions::READ)
  end

  can :manage_form do |user, form|
    form.permission_granted?(user, FormPermissions::MANAGE)
  end

  can :manage_form_draft do |user, form|
    !form.published? &&
      form.permission_granted?(user, FormPermissions::MANAGE_DRAFT)
  end

  can :manage_form_users do |user, form|
    form.permission_granted?(user, FormPermissions::USERS_MANAGE) ||
      form.team.permission_granted?(user, TeamPermissions::MANAGE)
  end

  can :restore_form do |user, form|
    form.archived? && form.permission_granted?(user, FormPermissions::MANAGE)
  end

  can :archive_form do |user, form|
    form.active? && form.permission_granted?(user, FormPermissions::MANAGE)
  end

  can :clone_form do |user, form|
    can_read_form?(user, form) && can_create_forms?(user, form.team)
  end

  can :publish_form do |user, form|
    !form.published? && form.permission_granted?(user, FormPermissions::MANAGE)
  end

  can :unpublish_form do |user, form|
    form.published? && form.permission_granted?(user, FormPermissions::MANAGE) && form.unused?
  end
end
