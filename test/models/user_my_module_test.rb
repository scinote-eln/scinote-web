require 'test_helper'

class UserMyModuleTest < ActiveSupport::TestCase

  test "should validate with correct data" do
    assert user_my_modules(:one).valid?
    assert user_my_modules(:two).valid?
    assert user_my_modules(:three).valid?
  end

  test "should not save user module without user" do
    user_my_modules(:without_user).user = nil

    assert_not user_my_modules(:without_user).save,
      "Saved user module without user"
  end

  test "should not validate with non existing user" do
    assert_not user_my_modules(:non_existing_user).valid?
  end

  test "should not save user module without module" do
    user_my_modules(:without_module).my_module = nil

    assert_not user_my_modules(:without_module).save,
      "Saved user module without module"
  end

  test "should not validate with non existing my_module" do
    assert_not user_my_modules(:non_existing_module).valid?
  end
end
