require 'test_helper'

class ProtocolTest < ActiveSupport::TestCase
  def setup
    @user = users(:steve)
    @team = teams(:biosistemika)
    @my_module = my_modules(:sample_prep)
    @global = protocols(:rna_test_protocol_global)

    @p = Protocol.new(
      my_module: @my_module,
      team: @team
    )
  end

  should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
  should validate_length_of(:description).is_at_most(Constants::TEXT_MAX_LENGTH)

  test 'protocol_type enum works' do
    @p.protocol_type = :unlinked
    assert @p.in_module?
    @p.protocol_type = :linked
    assert @p.in_module?
    @p.protocol_type = :in_repository_private
    assert @p.in_repository?
    @p.protocol_type = :in_repository_public
    assert @p.in_repository?
    @p.protocol_type = :in_repository_archived
    assert @p.in_repository?
  end

  test 'should not validate without team' do
    @p.team = @team
    assert @p.valid?
    @p.team = nil
    assert_not @p.valid?
  end

  test 'should not validate without protocol type' do
    assert @p.valid?
    @p.protocol_type = nil
    assert_not @p.valid?
  end

  test 'should count steps of protocol' do
    assert_equal 0, @p.number_of_steps
  end

  test 'specific validations for :unlinked' do
    p = new_unlinked_protocol
    assert p.valid?
    p.my_module = nil
    assert_not p.valid?
  end

  test 'specific validations for :linked' do
    p = new_linked_protocol
    assert p.valid?

    p.my_module = nil
    assert_not p.valid?

    p = new_linked_protocol
    p.added_by = nil
    assert_not p.valid?

    p = new_linked_protocol
    p.parent = nil
    assert_not p.valid?

    p = new_linked_protocol
    p.parent_updated_at = nil
    assert_not p.valid?
  end

  test 'specific validations for :in_repository' do
    [
      :in_repository_private,
      :in_repository_public,
      :in_repository_archived
    ].each do |protocol_type|
      p = new_repository_protocol(protocol_type)
      if protocol_type == :in_repository_archived
        p.archived_by = @user
        p.archived_on = Time.now
      elsif protocol_type == :in_repository_public
        p.published_on = Time.now
      end
      assert p.valid?

      p.name = nil
      assert_not p.valid?

      p = new_repository_protocol(protocol_type)
      p.added_by = nil
      assert_not p.valid?

      p = new_repository_protocol(protocol_type)
      p.my_module = @my_module
      assert_not p.valid?

      p = new_repository_protocol(protocol_type)
      p.parent = @global
      assert_not p.valid?

      p = new_repository_protocol(protocol_type)
      p.parent_updated_at = Time.now
      assert_not p.valid?
    end
  end

  test 'specific validations for :in_repository_public' do
    p = new_repository_protocol(:in_repository_public)
    p.published_on = nil
    assert_not p.valid?

    p.published_on = Time.now
    assert p.valid?
  end

  test 'specific validations for :in_repository_archived' do
    p = new_repository_protocol(:in_repository_archived)
    p.archived_by = nil
    p.archived_on = nil
    assert_not p.valid?

    p.archived_by = @user
    assert_not p.valid?

    p.archived_on = Time.now
    assert p.valid?
  end

  private

  def new_unlinked_protocol
    Protocol.new(
      my_module: @my_module,
      team: @team
    )
  end

  def new_linked_protocol
    Protocol.new(
      protocol_type: :linked,
      my_module: @my_module,
      team: @team,
      added_by: @user,
      parent: @global,
      parent_updated_at: @global.updated_at
    )
  end

  def new_repository_protocol(type)
    Protocol.new(
      name: 'Test protocol',
      protocol_type: type,
      team: @team,
      added_by: @user
    )
  end
end
