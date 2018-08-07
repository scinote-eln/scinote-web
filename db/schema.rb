# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150716062110) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assets", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "file_file_name"
    t.string "file_content_type"
    t.integer "file_file_size"
    t.datetime "file_updated_at"
    t.index ["created_at"], name: "index_assets_on_created_at"
  end

  create_table "checklist_items", id: :serial, force: :cascade do |t|
    t.string "text", null: false
    t.boolean "checked", default: false, null: false
    t.integer "checklist_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checklist_id"], name: "index_checklist_items_on_checklist_id"
  end

  create_table "checklists", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "step_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.string "message", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_comments_on_created_at"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "connections", id: :serial, force: :cascade do |t|
    t.integer "input_id", null: false
    t.integer "output_id", null: false
  end

  create_table "logs", id: :serial, force: :cascade do |t|
    t.integer "team_id", null: false
    t.string "message", null: false
  end

  create_table "my_module_comments", id: :serial, force: :cascade do |t|
    t.integer "my_module_id", null: false
    t.integer "comment_id", null: false
    t.index ["my_module_id", "comment_id"], name: "index_my_module_comments_on_my_module_id_and_comment_id"
  end

  create_table "my_module_groups", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "my_module_tags", id: :serial, force: :cascade do |t|
    t.integer "my_module_id"
    t.integer "tag_id"
    t.index ["my_module_id"], name: "index_my_module_tags_on_my_module_id"
    t.index ["tag_id"], name: "index_my_module_tags_on_tag_id"
  end

  create_table "my_modules", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "due_date"
    t.string "description"
    t.integer "x", default: 0, null: false
    t.integer "y", default: 0, null: false
    t.integer "project_id", null: false
    t.integer "my_module_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["my_module_group_id"], name: "index_my_modules_on_my_module_group_id"
    t.index ["project_id"], name: "index_my_modules_on_project_id"
  end

  create_table "project_comments", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "comment_id", null: false
    t.index ["project_id", "comment_id"], name: "index_project_comments_on_project_id_and_comment_id"
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "visibility", default: 0, null: false
    t.datetime "due_date"
    t.integer "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false, null: false
    t.datetime "archived_on"
  end

  create_table "result_assets", id: :serial, force: :cascade do |t|
    t.integer "result_id", null: false
    t.integer "asset_id", null: false
    t.index ["result_id", "asset_id"], name: "index_result_assets_on_result_id_and_asset_id"
  end

  create_table "result_comments", id: :serial, force: :cascade do |t|
    t.integer "result_id", null: false
    t.integer "comment_id", null: false
    t.index ["result_id", "comment_id"], name: "index_result_comments_on_result_id_and_comment_id"
  end

  create_table "results", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "my_module_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_results_on_created_at"
    t.index ["my_module_id"], name: "index_results_on_my_module_id"
    t.index ["user_id"], name: "index_results_on_user_id"
  end

  create_table "step_assets", id: :serial, force: :cascade do |t|
    t.integer "step_id", null: false
    t.integer "asset_id", null: false
    t.index ["step_id", "asset_id"], name: "index_step_assets_on_step_id_and_asset_id"
  end

  create_table "step_comments", id: :serial, force: :cascade do |t|
    t.integer "step_id", null: false
    t.integer "comment_id", null: false
    t.index ["step_id", "comment_id"], name: "index_step_comments_on_step_id_and_comment_id"
  end

  create_table "steps", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "position", null: false
    t.boolean "completed", null: false
    t.datetime "completed_on"
    t.integer "user_id", null: false
    t.integer "my_module_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_steps_on_created_at"
    t.index ["my_module_id"], name: "index_steps_on_my_module_id"
    t.index ["position"], name: "index_steps_on_position"
    t.index ["user_id"], name: "index_steps_on_user_id"
  end

  create_table "tables", id: :serial, force: :cascade do |t|
    t.binary "contents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_tables_on_created_at"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

  create_table "user_projects", id: :serial, force: :cascade do |t|
    t.integer "role", default: 0
    t.integer "user_id", null: false
    t.integer "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_teams", id: :serial, force: :cascade do |t|
    t.integer "role", default: 1, null: false
    t.integer "user_id", null: false
    t.integer "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "full_name", null: false
    t.string "initials", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.integer "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "checklists", "steps"
  add_foreign_key "comments", "users"
  add_foreign_key "connections", "my_modules", column: "input_id"
  add_foreign_key "connections", "my_modules", column: "output_id"
  add_foreign_key "logs", "teams"
  add_foreign_key "my_module_comments", "my_modules"
  add_foreign_key "my_modules", "projects"
  add_foreign_key "project_comments", "projects"
  add_foreign_key "projects", "teams"
  add_foreign_key "result_assets", "assets"
  add_foreign_key "result_comments", "results"
  add_foreign_key "results", "my_modules"
  add_foreign_key "results", "users"
  add_foreign_key "step_assets", "assets"
  add_foreign_key "step_assets", "steps"
  add_foreign_key "step_comments", "comments"
  add_foreign_key "step_comments", "steps"
  add_foreign_key "steps", "my_modules"
  add_foreign_key "steps", "users"
  add_foreign_key "user_projects", "projects"
  add_foreign_key "user_projects", "users"
  add_foreign_key "user_teams", "teams"
  add_foreign_key "user_teams", "users"
end
