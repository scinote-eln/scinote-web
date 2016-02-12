require 'test_helper'

class CanvasUpdateTest < ActionDispatch::IntegrationTest
  def setup
    # Preload user
    @user = users(:steve)
    @password = "hidden_password"

    # Preload project
    @project = projects(:interfaces)

    # Initialize empty params
    @connections = (
      @project.my_modules
      .select { |m| m.active? }
      .collect { |m| m.outputs.collect { |c| "#{c.from.id},#{c.to.id}" } }
    ).flatten.join(",")
    @positions = (
      @project.my_modules
      .select { |m| m.active? }
      .collect { |m| "#{m.id},#{m.x},#{m.y}" }
    ).join(";")
    @add = ""
    @add_names = ""
    @rename = "{}"
    @cloned = ""
    @remove = ""
    @module_groups = "{}"

    # Sign in as user first
    sign_in @user, @password
  end

  test "should pass without arguments" do
    error = false
    begin
      post_via_redirect canvas_project_url(@project)
    rescue Exception
      error = true
    end
    assert_not error
  end

  test "should pass with valid arguments" do
    post canvas_project_url(@project),
    connections: @connections,
    positions: @positions,
    add: @add,
    "add-names" => @add_names,
    rename: @rename,
    cloned: @cloned,
    remove: @remove,
    "module-groups" => @module_groups

    assert_redirected_to canvas_project_url(@project)
  end

  test "should not pass with invalid project id" do
    post_via_redirect canvas_project_url(-5)
    assert_redirected_to_404
  end

  test "should not pass with invalid connections" do
    m1 = my_modules(:qpcr).id
    m2 = my_modules(:no_group).id

    invalid_connections = [
      "1,2,3", # Not dividable by 2
      "kkj44gk", # Invalid string
      2015, # Number, not dividable by 2
      "#{m1},#{m2},#{m2},#{m1}" # Cycle
    ]

    invalid_connections.each do |conn|
      post_via_redirect canvas_project_url(@project),
      connections: conn,
      positions: @positions,
      add: @add,
      "add-names" => @add_names,
      rename: @rename,
      cloned: @cloned,
      remove: @remove,
      "module-groups" => @module_groups

      assert_redirected_to_403
    end
  end

  test "should not pass with invalid positions" do
    invalid_positions = [
      "fkgdfgfd",
      "dsfldkfsd;ldfkdsl;asdsa", # Subtsrings not divided by commas
      "a,b,c,d;1,2,3,4", # Substrings have lenghts of 4
      "m1,2,a;m2,b,3", # Position is not an integer
      "m1,1,2;m2,1,2;m3,2,2" # Multiple modules cannot have same position
    ]

    invalid_positions.each do |pos|
      post_via_redirect canvas_project_url(@project),
      connections: @connections,
      positions: pos,
      add: @add,
      "add-names" => @add_names,
      rename: @rename,
      cloned: @cloned,
      remove: @remove,
      "module-groups" => @module_groups

      assert_redirected_to_403
    end
  end

  test "should not pass with invalid add strings" do
    invalid_positions = [
      "", # No positions provided
      "m1,0,1;m2,4,5", # Invalid module names (too short)
      "m1,0,1;m2,4,5" # Names.length != Ids.length
    ]
    invalid_adds = [
      "m1,m2", # No positions provided
      "m1,m2", # Invalid module names (too short)
      "m1,m2" # Names.length != Ids.length
    ]
    invalid_names = [
      "module1,module2", # No positions provided
      "a,b", # Invalid module names (too short)
      "module1,module2,module3" # Names.length != Ids.length
    ]

    invalid_adds.zip(invalid_names).each_with_index do |val, i|
      pos = @positions + ";" + invalid_positions[i]
      post_via_redirect canvas_project_url(@project),
      connections: @connections,
      positions: pos,
      add: val[0],
      "add-names" => val[1],
      rename: @rename,
      cloned: @cloned,
      remove: @remove,
      "module-groups" => @module_groups

      assert_redirected_to_403
    end
  end

  test "should not pass with invalid rename strings" do
    invalid_renames = [
      "asdkjkasd asd",
      "'m1':'abule'",
      "{15:'aa', 'ac': 23}",
      "[]",
    ]

    invalid_renames.each do |val|
      post_via_redirect canvas_project_url(@project),
        connections: @connections,
        positions: @positions,
        add: @adds,
        "add-names" => @add_names,
        rename: val,
        cloned: @cloned,
        remove: @remove,
        "module-groups" => @module_groups

      assert_redirected_to_403
    end
  end

  test "should not pass with invalid clone strings" do
    positions = "m1,0,1;m2,4,5"
    adds = "m1,m2"
    names = "module1|module2"

    invalid_clones = [
      "kgjfdklg;123;aa2", # Invalid strings
      "5k6,m1;zulu,m2", # Invalid source module
      "133,m3;233,m4" # Cloned IDs not present in add string
    ]

    invalid_clones.each do |val|
      post_via_redirect canvas_project_url(@project),
        connections: @connections,
        positions: positions,
        add: adds,
        "add-names" => names,
        rename: @rename,
        cloned: val,
        remove: @remove,
        "module-groups" => @module_groups

      assert_redirected_to_403
    end
  end

  test "should not pass with invalid remove strings" do
    invalid_removes = [
      "a,b,c" # Non-integers
    ]

    invalid_removes.each do |remove|
      post_via_redirect canvas_project_url(@project),
      connections: @connections,
      positions: @positions,
      add: @add,
      "add-names" => @add_names,
      rename: @rename,
      cloned: @cloned,
      remove: remove,
      "module-groups" => @module_groups

      assert_redirected_to_403
    end
  end

  test "should not pass with invalid module group strings" do
    invalid_module_groups = [
      "asdkjkasd asd",
      "'m1':'abule'",
      "{15:'aa', 'ac': 23}",
      "[]",
    ]

    invalid_module_groups.each do |val|
      post_via_redirect canvas_project_url(@project),
        connections: @connections,
        positions: @positions,
        add: @adds,
        "add-names" => @add_names,
        rename: @rename,
        cloned: @cloned,
        remove: @remove,
        "module-groups" => val

      assert_redirected_to_403
    end
  end

  private

  # Alas, Devise test helpers don't work in integration tests,
  # so this is a "manual" login
  def sign_in(user, password)
    post_via_redirect user_session_url, "user[email]" => user.email, "user[password]" => password
  end
end
