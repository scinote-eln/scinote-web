# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20170619125051) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_trgm"
  enable_extension "btree_gist"

  create_table "activities", force: :cascade do |t|
    t.integer  "my_module_id"
    t.integer  "user_id"
    t.integer  "type_of",       null: false
    t.string   "message",       null: false
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "project_id",    null: false
    t.integer  "experiment_id"
  end

  add_index "activities", ["created_at"], name: "index_activities_on_created_at", using: :btree
  add_index "activities", ["experiment_id"], name: "index_activities_on_experiment_id", using: :btree
  add_index "activities", ["my_module_id"], name: "index_activities_on_my_module_id", using: :btree
  add_index "activities", ["project_id"], name: "index_activities_on_project_id", using: :btree
  add_index "activities", ["type_of"], name: "index_activities_on_type_of", using: :btree
  add_index "activities", ["user_id"], name: "index_activities_on_user_id", using: :btree

  create_table "asset_text_data", force: :cascade do |t|
    t.text     "data",        null: false
    t.integer  "asset_id",    null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.tsvector "data_vector"
  end

  add_index "asset_text_data", ["asset_id"], name: "index_asset_text_data_on_asset_id", unique: true, using: :btree
  add_index "asset_text_data", ["data_vector"], name: "index_asset_text_data_on_data_vector", using: :gin

  create_table "assets", force: :cascade do |t|
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
    t.integer  "estimated_size",                   default: 0,     null: false
    t.boolean  "file_present",                     default: false, null: false
    t.string   "lock",                limit: 1024
    t.integer  "lock_ttl"
    t.integer  "version",                          default: 1
    t.boolean  "file_processing"
    t.integer  "team_id"
  end

  add_index "assets", ["created_at"], name: "index_assets_on_created_at", using: :btree
  add_index "assets", ["created_by_id"], name: "index_assets_on_created_by_id", using: :btree
  add_index "assets", ["last_modified_by_id"], name: "index_assets_on_last_modified_by_id", using: :btree
  add_index "assets", ["team_id"], name: "index_assets_on_team_id", using: :btree

  create_table "checklist_items", force: :cascade do |t|
    t.string   "text",                                null: false
    t.boolean  "checked",             default: false, null: false
    t.integer  "checklist_id",                        null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
    t.integer  "position"
  end

  add_index "checklist_items", ["checklist_id"], name: "index_checklist_items_on_checklist_id", using: :btree
  add_index "checklist_items", ["created_by_id"], name: "index_checklist_items_on_created_by_id", using: :btree
  add_index "checklist_items", ["last_modified_by_id"], name: "index_checklist_items_on_last_modified_by_id", using: :btree

  create_table "checklists", force: :cascade do |t|
    t.string   "name",                null: false
    t.integer  "step_id",             null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
  end

  add_index "checklists", ["created_by_id"], name: "index_checklists_on_created_by_id", using: :btree
  add_index "checklists", ["last_modified_by_id"], name: "index_checklists_on_last_modified_by_id", using: :btree
  add_index "checklists", ["step_id"], name: "index_checklists_on_step_id", using: :btree

  create_table "comments", force: :cascade do |t|
    t.string   "message",             null: false
    t.integer  "user_id",             null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "last_modified_by_id"
    t.string   "type"
    t.integer  "associated_id"
  end

  add_index "comments", ["associated_id"], name: "index_comments_on_associated_id", using: :btree
  add_index "comments", ["created_at"], name: "index_comments_on_created_at", using: :btree
  add_index "comments", ["last_modified_by_id"], name: "index_comments_on_last_modified_by_id", using: :btree
  add_index "comments", ["type"], name: "index_comments_on_type", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "connections", force: :cascade do |t|
    t.integer "input_id",  null: false
    t.integer "output_id", null: false
  end

  create_table "custom_fields", force: :cascade do |t|
    t.string   "name",                null: false
    t.integer  "user_id",             null: false
    t.integer  "team_id",             null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "last_modified_by_id"
  end

  add_index "custom_fields", ["last_modified_by_id"], name: "index_custom_fields_on_last_modified_by_id", using: :btree
  add_index "custom_fields", ["team_id"], name: "index_custom_fields_on_team_id", using: :btree
  add_index "custom_fields", ["user_id"], name: "index_custom_fields_on_user_id", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree
  add_index "delayed_jobs", ["queue"], name: "delayed_jobs_queue", using: :btree

  create_table "experiments", force: :cascade do |t|
    t.string   "name",                                     null: false
    t.text     "description"
    t.integer  "project_id",                               null: false
    t.integer  "created_by_id",                            null: false
    t.integer  "last_modified_by_id",                      null: false
    t.boolean  "archived",                 default: false, null: false
    t.integer  "archived_by_id"
    t.datetime "archived_on"
    t.integer  "restored_by_id"
    t.datetime "restored_on"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "workflowimg_file_name"
    t.string   "workflowimg_content_type"
    t.integer  "workflowimg_file_size"
    t.datetime "workflowimg_updated_at"
  end

  add_index "experiments", ["archived_by_id"], name: "index_experiments_on_archived_by_id", using: :btree
  add_index "experiments", ["created_by_id"], name: "index_experiments_on_created_by_id", using: :btree
  add_index "experiments", ["last_modified_by_id"], name: "index_experiments_on_last_modified_by_id", using: :btree
  add_index "experiments", ["name"], name: "index_experiments_on_name", using: :btree
  add_index "experiments", ["project_id"], name: "index_experiments_on_project_id", using: :btree
  add_index "experiments", ["restored_by_id"], name: "index_experiments_on_restored_by_id", using: :btree

  create_table "my_module_groups", force: :cascade do |t|
    t.string   "name",                      null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "created_by_id"
    t.integer  "experiment_id", default: 0, null: false
  end

  add_index "my_module_groups", ["created_by_id"], name: "index_my_module_groups_on_created_by_id", using: :btree
  add_index "my_module_groups", ["experiment_id"], name: "index_my_module_groups_on_experiment_id", using: :btree

  create_table "my_module_repository_rows", force: :cascade do |t|
    t.integer  "repository_row_id", null: false
    t.integer  "my_module_id"
    t.integer  "assigned_by_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "my_module_repository_rows", ["my_module_id", "repository_row_id"], name: "index_my_module_ids_repository_row_ids", using: :btree
  add_index "my_module_repository_rows", ["repository_row_id"], name: "index_my_module_repository_rows_on_repository_row_id", using: :btree

  create_table "my_module_tags", force: :cascade do |t|
    t.integer "my_module_id"
    t.integer "tag_id"
    t.integer "created_by_id"
  end

  add_index "my_module_tags", ["created_by_id"], name: "index_my_module_tags_on_created_by_id", using: :btree
  add_index "my_module_tags", ["my_module_id"], name: "index_my_module_tags_on_my_module_id", using: :btree
  add_index "my_module_tags", ["tag_id"], name: "index_my_module_tags_on_tag_id", using: :btree

  create_table "my_modules", force: :cascade do |t|
    t.string   "name",                                             null: false
    t.datetime "due_date"
    t.string   "description"
    t.integer  "x",                                default: 0,     null: false
    t.integer  "y",                                default: 0,     null: false
    t.integer  "my_module_group_id"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.boolean  "archived",                         default: false, null: false
    t.datetime "archived_on"
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
    t.integer  "archived_by_id"
    t.integer  "restored_by_id"
    t.datetime "restored_on"
    t.integer  "nr_of_assigned_samples",           default: 0
    t.integer  "workflow_order",                   default: -1,    null: false
    t.integer  "experiment_id",                    default: 0,     null: false
    t.integer  "state",                  limit: 2, default: 0
    t.datetime "completed_on"
  end

  add_index "my_modules", ["archived_by_id"], name: "index_my_modules_on_archived_by_id", using: :btree
  add_index "my_modules", ["created_by_id"], name: "index_my_modules_on_created_by_id", using: :btree
  add_index "my_modules", ["experiment_id"], name: "index_my_modules_on_experiment_id", using: :btree
  add_index "my_modules", ["last_modified_by_id"], name: "index_my_modules_on_last_modified_by_id", using: :btree
  add_index "my_modules", ["my_module_group_id"], name: "index_my_modules_on_my_module_group_id", using: :btree
  add_index "my_modules", ["restored_by_id"], name: "index_my_modules_on_restored_by_id", using: :btree

  create_table "notifications", force: :cascade do |t|
    t.string   "title"
    t.string   "message"
    t.integer  "type_of",           null: false
    t.integer  "generator_user_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "notifications", ["created_at"], name: "index_notifications_on_created_at", using: :btree

  create_table "projects", force: :cascade do |t|
    t.string   "name",                                null: false
    t.integer  "visibility",          default: 0,     null: false
    t.datetime "due_date"
    t.integer  "team_id",                             null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.boolean  "archived",            default: false, null: false
    t.datetime "archived_on"
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
    t.integer  "archived_by_id"
    t.integer  "restored_by_id"
    t.datetime "restored_on"
    t.string   "experiments_order"
  end

  add_index "projects", ["archived_by_id"], name: "index_projects_on_archived_by_id", using: :btree
  add_index "projects", ["created_by_id"], name: "index_projects_on_created_by_id", using: :btree
  add_index "projects", ["last_modified_by_id"], name: "index_projects_on_last_modified_by_id", using: :btree
  add_index "projects", ["restored_by_id"], name: "index_projects_on_restored_by_id", using: :btree
  add_index "projects", ["team_id"], name: "index_projects_on_team_id", using: :btree

  create_table "protocol_keywords", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "nr_of_protocols", default: 0
    t.integer  "team_id",                     null: false
  end

  add_index "protocol_keywords", ["team_id"], name: "index_protocol_keywords_on_team_id", using: :btree

  create_table "protocol_protocol_keywords", force: :cascade do |t|
    t.integer "protocol_id",         null: false
    t.integer "protocol_keyword_id", null: false
  end

  add_index "protocol_protocol_keywords", ["protocol_id"], name: "index_protocol_protocol_keywords_on_protocol_id", using: :btree
  add_index "protocol_protocol_keywords", ["protocol_keyword_id"], name: "index_protocol_protocol_keywords_on_protocol_keyword_id", using: :btree

  create_table "protocols", force: :cascade do |t|
    t.string   "name"
    t.text     "authors"
    t.text     "description"
    t.integer  "added_by_id"
    t.integer  "my_module_id"
    t.integer  "team_id",                           null: false
    t.integer  "protocol_type",         default: 0, null: false
    t.integer  "parent_id"
    t.datetime "parent_updated_at"
    t.integer  "archived_by_id"
    t.datetime "archived_on"
    t.integer  "restored_by_id"
    t.datetime "restored_on"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.datetime "published_on"
    t.integer  "nr_of_linked_children", default: 0
  end

  add_index "protocols", ["added_by_id"], name: "index_protocols_on_added_by_id", using: :btree
  add_index "protocols", ["archived_by_id"], name: "index_protocols_on_archived_by_id", using: :btree
  add_index "protocols", ["my_module_id"], name: "index_protocols_on_my_module_id", using: :btree
  add_index "protocols", ["parent_id"], name: "index_protocols_on_parent_id", using: :btree
  add_index "protocols", ["protocol_type"], name: "index_protocols_on_protocol_type", using: :btree
  add_index "protocols", ["restored_by_id"], name: "index_protocols_on_restored_by_id", using: :btree
  add_index "protocols", ["team_id"], name: "index_protocols_on_team_id", using: :btree

  create_table "report_elements", force: :cascade do |t|
    t.integer  "position",                  null: false
    t.integer  "type_of",                   null: false
    t.integer  "sort_order",    default: 0
    t.integer  "report_id"
    t.integer  "parent_id"
    t.integer  "project_id"
    t.integer  "my_module_id"
    t.integer  "step_id"
    t.integer  "result_id"
    t.integer  "checklist_id"
    t.integer  "asset_id"
    t.integer  "table_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "experiment_id"
    t.integer  "repository_id"
  end

  add_index "report_elements", ["asset_id"], name: "index_report_elements_on_asset_id", using: :btree
  add_index "report_elements", ["checklist_id"], name: "index_report_elements_on_checklist_id", using: :btree
  add_index "report_elements", ["experiment_id"], name: "index_report_elements_on_experiment_id", using: :btree
  add_index "report_elements", ["my_module_id"], name: "index_report_elements_on_my_module_id", using: :btree
  add_index "report_elements", ["parent_id"], name: "index_report_elements_on_parent_id", using: :btree
  add_index "report_elements", ["project_id"], name: "index_report_elements_on_project_id", using: :btree
  add_index "report_elements", ["report_id"], name: "index_report_elements_on_report_id", using: :btree
  add_index "report_elements", ["repository_id"], name: "index_report_elements_on_repository_id", using: :btree
  add_index "report_elements", ["result_id"], name: "index_report_elements_on_result_id", using: :btree
  add_index "report_elements", ["step_id"], name: "index_report_elements_on_step_id", using: :btree
  add_index "report_elements", ["table_id"], name: "index_report_elements_on_table_id", using: :btree

  create_table "reports", force: :cascade do |t|
    t.string   "name",                null: false
    t.string   "description"
    t.integer  "project_id",          null: false
    t.integer  "user_id",             null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "last_modified_by_id"
  end

  add_index "reports", ["last_modified_by_id"], name: "index_reports_on_last_modified_by_id", using: :btree
  add_index "reports", ["project_id"], name: "index_reports_on_project_id", using: :btree
  add_index "reports", ["user_id"], name: "index_reports_on_user_id", using: :btree

  create_table "repositories", force: :cascade do |t|
    t.integer  "team_id"
    t.integer  "created_by_id", null: false
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "repositories", ["team_id"], name: "index_repositories_on_team_id", using: :btree

  create_table "repository_cells", force: :cascade do |t|
    t.integer  "repository_row_id"
    t.integer  "repository_column_id"
    t.integer  "value_id"
    t.string   "value_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "repository_cells", ["repository_column_id"], name: "index_repository_cells_on_repository_column_id", using: :btree
  add_index "repository_cells", ["repository_row_id"], name: "index_repository_cells_on_repository_row_id", using: :btree
  add_index "repository_cells", ["value_type", "value_id"], name: "index_repository_cells_on_value_type_and_value_id", using: :btree

  create_table "repository_columns", force: :cascade do |t|
    t.integer  "repository_id"
    t.integer  "created_by_id", null: false
    t.string   "name"
    t.integer  "data_type",     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "repository_columns", ["repository_id"], name: "index_repository_columns_on_repository_id", using: :btree

  create_table "repository_date_values", force: :cascade do |t|
    t.datetime "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id",       null: false
    t.integer  "last_modified_by_id", null: false
  end

  create_table "repository_rows", force: :cascade do |t|
    t.integer  "repository_id"
    t.integer  "created_by_id",       null: false
    t.integer  "last_modified_by_id", null: false
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "repository_rows", ["name"], name: "index_repository_rows_on_name", using: :btree
  add_index "repository_rows", ["repository_id"], name: "index_repository_rows_on_repository_id", using: :btree

  create_table "repository_table_states", force: :cascade do |t|
    t.jsonb    "state",         null: false
    t.integer  "user_id",       null: false
    t.integer  "repository_id", null: false
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "repository_table_states", ["repository_id"], name: "index_repository_table_states_on_repository_id", using: :btree
  add_index "repository_table_states", ["user_id"], name: "index_repository_table_states_on_user_id", using: :btree

  create_table "repository_text_values", force: :cascade do |t|
    t.string   "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id",       null: false
    t.integer  "last_modified_by_id", null: false
  end

  create_table "result_assets", force: :cascade do |t|
    t.integer "result_id", null: false
    t.integer "asset_id",  null: false
  end

  add_index "result_assets", ["result_id", "asset_id"], name: "index_result_assets_on_result_id_and_asset_id", using: :btree

  create_table "result_tables", force: :cascade do |t|
    t.integer "result_id", null: false
    t.integer "table_id",  null: false
  end

  add_index "result_tables", ["result_id", "table_id"], name: "index_result_tables_on_result_id_and_table_id", using: :btree

  create_table "result_texts", force: :cascade do |t|
    t.string  "text",      null: false
    t.integer "result_id", null: false
  end

  add_index "result_texts", ["result_id"], name: "index_result_texts_on_result_id", using: :btree

  create_table "results", force: :cascade do |t|
    t.string   "name"
    t.integer  "my_module_id",                        null: false
    t.integer  "user_id",                             null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.boolean  "archived",            default: false, null: false
    t.datetime "archived_on"
    t.integer  "last_modified_by_id"
    t.integer  "archived_by_id"
    t.integer  "restored_by_id"
    t.datetime "restored_on"
  end

  add_index "results", ["archived_by_id"], name: "index_results_on_archived_by_id", using: :btree
  add_index "results", ["created_at"], name: "index_results_on_created_at", using: :btree
  add_index "results", ["last_modified_by_id"], name: "index_results_on_last_modified_by_id", using: :btree
  add_index "results", ["my_module_id"], name: "index_results_on_my_module_id", using: :btree
  add_index "results", ["restored_by_id"], name: "index_results_on_restored_by_id", using: :btree
  add_index "results", ["user_id"], name: "index_results_on_user_id", using: :btree

  create_table "sample_custom_fields", force: :cascade do |t|
    t.string   "value",           null: false
    t.integer  "custom_field_id", null: false
    t.integer  "sample_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "sample_custom_fields", ["custom_field_id"], name: "index_sample_custom_fields_on_custom_field_id", using: :btree
  add_index "sample_custom_fields", ["sample_id"], name: "index_sample_custom_fields_on_sample_id", using: :btree

  create_table "sample_groups", force: :cascade do |t|
    t.string   "name",                                    null: false
    t.string   "color",               default: "#ff0000", null: false
    t.integer  "team_id",                                 null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
  end

  add_index "sample_groups", ["created_by_id"], name: "index_sample_groups_on_created_by_id", using: :btree
  add_index "sample_groups", ["last_modified_by_id"], name: "index_sample_groups_on_last_modified_by_id", using: :btree
  add_index "sample_groups", ["team_id"], name: "index_sample_groups_on_team_id", using: :btree

  create_table "sample_my_modules", force: :cascade do |t|
    t.integer  "sample_id",      null: false
    t.integer  "my_module_id",   null: false
    t.integer  "assigned_by_id"
    t.datetime "assigned_on"
  end

  add_index "sample_my_modules", ["assigned_by_id"], name: "index_sample_my_modules_on_assigned_by_id", using: :btree
  add_index "sample_my_modules", ["sample_id", "my_module_id"], name: "index_sample_my_modules_on_sample_id_and_my_module_id", using: :btree

  create_table "sample_types", force: :cascade do |t|
    t.string   "name",                null: false
    t.integer  "team_id",             null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
  end

  add_index "sample_types", ["created_by_id"], name: "index_sample_types_on_created_by_id", using: :btree
  add_index "sample_types", ["last_modified_by_id"], name: "index_sample_types_on_last_modified_by_id", using: :btree
  add_index "sample_types", ["team_id"], name: "index_sample_types_on_team_id", using: :btree

  create_table "samples", force: :cascade do |t|
    t.string   "name",                                  null: false
    t.integer  "user_id",                               null: false
    t.integer  "team_id",                               null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "sample_group_id"
    t.integer  "sample_type_id"
    t.integer  "last_modified_by_id"
    t.integer  "nr_of_modules_assigned_to", default: 0
  end

  add_index "samples", ["last_modified_by_id"], name: "index_samples_on_last_modified_by_id", using: :btree
  add_index "samples", ["sample_group_id"], name: "index_samples_on_sample_group_id", using: :btree
  add_index "samples", ["sample_type_id"], name: "index_samples_on_sample_type_id", using: :btree
  add_index "samples", ["team_id"], name: "index_samples_on_team_id", using: :btree
  add_index "samples", ["user_id"], name: "index_samples_on_user_id", using: :btree

  create_table "samples_tables", force: :cascade do |t|
    t.jsonb    "status",     default: {"time"=>0, "order"=>[[2, "desc"]], "start"=>0, "length"=>10, "search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "columns"=>[{"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true}, {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true}, {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true}, {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true}, {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true}, {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true}, {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true}], "assigned"=>"all", "ColReorder"=>[0, 1, 2, 3, 4, 5, 6]}, null: false
    t.integer  "user_id",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      null: false
    t.integer  "team_id",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      null: false
    t.datetime "created_at",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   null: false
    t.datetime "updated_at",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   null: false
  end

  add_index "samples_tables", ["team_id"], name: "index_samples_tables_on_team_id", using: :btree
  add_index "samples_tables", ["user_id"], name: "index_samples_tables_on_user_id", using: :btree

  create_table "settings", force: :cascade do |t|
    t.text  "type",                null: false
    t.jsonb "values", default: {}, null: false
  end

  add_index "settings", ["type"], name: "index_settings_on_type", unique: true, using: :btree

  create_table "step_assets", force: :cascade do |t|
    t.integer "step_id",  null: false
    t.integer "asset_id", null: false
  end

  add_index "step_assets", ["step_id", "asset_id"], name: "index_step_assets_on_step_id_and_asset_id", using: :btree

  create_table "step_tables", force: :cascade do |t|
    t.integer "step_id",  null: false
    t.integer "table_id", null: false
  end

  add_index "step_tables", ["step_id", "table_id"], name: "index_step_tables_on_step_id_and_table_id", unique: true, using: :btree

  create_table "steps", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "position",            null: false
    t.boolean  "completed",           null: false
    t.datetime "completed_on"
    t.integer  "user_id",             null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "last_modified_by_id"
    t.integer  "protocol_id",         null: false
  end

  add_index "steps", ["created_at"], name: "index_steps_on_created_at", using: :btree
  add_index "steps", ["last_modified_by_id"], name: "index_steps_on_last_modified_by_id", using: :btree
  add_index "steps", ["position"], name: "index_steps_on_position", using: :btree
  add_index "steps", ["protocol_id"], name: "index_steps_on_protocol_id", using: :btree
  add_index "steps", ["user_id"], name: "index_steps_on_user_id", using: :btree

  create_table "tables", force: :cascade do |t|
    t.binary   "contents",                         null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
    t.tsvector "data_vector"
    t.string   "name",                default: ""
    t.integer  "team_id"
  end

  add_index "tables", ["created_at"], name: "index_tables_on_created_at", using: :btree
  add_index "tables", ["created_by_id"], name: "index_tables_on_created_by_id", using: :btree
  add_index "tables", ["data_vector"], name: "index_tables_on_data_vector", using: :gin
  add_index "tables", ["last_modified_by_id"], name: "index_tables_on_last_modified_by_id", using: :btree
  add_index "tables", ["team_id"], name: "index_tables_on_team_id", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string   "name",                                    null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.string   "color",               default: "#ff0000", null: false
    t.integer  "project_id",                              null: false
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
  end

  add_index "tags", ["created_by_id"], name: "index_tags_on_created_by_id", using: :btree
  add_index "tags", ["last_modified_by_id"], name: "index_tags_on_last_modified_by_id", using: :btree
  add_index "tags", ["project_id"], name: "index_tags_on_project_id", using: :btree

  create_table "teams", force: :cascade do |t|
    t.string   "name",                                            null: false
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
    t.string   "description"
    t.integer  "space_taken",         limit: 8, default: 1048576, null: false
  end

  add_index "teams", ["created_by_id"], name: "index_teams_on_created_by_id", using: :btree
  add_index "teams", ["last_modified_by_id"], name: "index_teams_on_last_modified_by_id", using: :btree
  add_index "teams", ["name"], name: "index_teams_on_name", using: :btree

  create_table "temp_files", force: :cascade do |t|
    t.string   "session_id",        null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
  end

  create_table "tiny_mce_assets", force: :cascade do |t|
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "estimated_size",     default: 0, null: false
    t.integer  "step_id"
    t.integer  "team_id"
    t.integer  "result_text_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "tiny_mce_assets", ["result_text_id"], name: "index_tiny_mce_assets_on_result_text_id", using: :btree
  add_index "tiny_mce_assets", ["step_id"], name: "index_tiny_mce_assets_on_step_id", using: :btree
  add_index "tiny_mce_assets", ["team_id"], name: "index_tiny_mce_assets_on_team_id", using: :btree

  create_table "tokens", force: :cascade do |t|
    t.string  "token",   null: false
    t.integer "ttl",     null: false
    t.integer "user_id", null: false
  end

  create_table "user_my_modules", force: :cascade do |t|
    t.integer  "user_id",        null: false
    t.integer  "my_module_id",   null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "assigned_by_id"
  end

  add_index "user_my_modules", ["assigned_by_id"], name: "index_user_my_modules_on_assigned_by_id", using: :btree
  add_index "user_my_modules", ["my_module_id"], name: "index_user_my_modules_on_my_module_id", using: :btree
  add_index "user_my_modules", ["user_id"], name: "index_user_my_modules_on_user_id", using: :btree

  create_table "user_notifications", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "notification_id"
    t.boolean  "checked",         default: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "user_notifications", ["checked"], name: "index_user_notifications_on_checked", using: :btree
  add_index "user_notifications", ["notification_id"], name: "index_user_notifications_on_notification_id", using: :btree
  add_index "user_notifications", ["user_id"], name: "index_user_notifications_on_user_id", using: :btree

  create_table "user_projects", force: :cascade do |t|
    t.integer  "role"
    t.integer  "user_id",        null: false
    t.integer  "project_id",     null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "assigned_by_id"
  end

  add_index "user_projects", ["assigned_by_id"], name: "index_user_projects_on_assigned_by_id", using: :btree
  add_index "user_projects", ["project_id"], name: "index_user_projects_on_project_id", using: :btree
  add_index "user_projects", ["user_id"], name: "index_user_projects_on_user_id", using: :btree

  create_table "user_teams", force: :cascade do |t|
    t.integer  "role",           default: 1, null: false
    t.integer  "user_id",                    null: false
    t.integer  "team_id",                    null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "assigned_by_id"
  end

  add_index "user_teams", ["assigned_by_id"], name: "index_user_teams_on_assigned_by_id", using: :btree
  add_index "user_teams", ["team_id"], name: "index_user_teams_on_team_id", using: :btree
  add_index "user_teams", ["user_id"], name: "index_user_teams_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "full_name",                                                    null: false
    t.string   "initials",                                                     null: false
    t.string   "email",                                        default: "",    null: false
    t.string   "encrypted_password",                           default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                                default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                                   null: false
    t.datetime "updated_at",                                                   null: false
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "time_zone",                                    default: "UTC"
    t.string   "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.integer  "invitations_count",                            default: 0
    t.integer  "tutorial_status",                              default: 0,     null: false
    t.boolean  "assignments_notification",                     default: true
    t.boolean  "recent_notification",                          default: true
    t.boolean  "assignments_notification_email",               default: false
    t.boolean  "recent_notification_email",                    default: false
    t.integer  "current_team_id"
    t.boolean  "system_message_notification_email",            default: false
    t.string   "authentication_token",              limit: 30
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["invitations_count"], name: "index_users_on_invitations_count", using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "wopi_actions", force: :cascade do |t|
    t.string  "action",      null: false
    t.string  "extension",   null: false
    t.string  "urlsrc",      null: false
    t.integer "wopi_app_id", null: false
  end

  add_index "wopi_actions", ["extension", "action"], name: "index_wopi_actions_on_extension_and_action", using: :btree

  create_table "wopi_apps", force: :cascade do |t|
    t.string  "name",              null: false
    t.string  "icon",              null: false
    t.integer "wopi_discovery_id", null: false
  end

  create_table "wopi_discoveries", force: :cascade do |t|
    t.integer "expires",           null: false
    t.string  "proof_key_mod",     null: false
    t.string  "proof_key_exp",     null: false
    t.string  "proof_key_old_mod", null: false
    t.string  "proof_key_old_exp", null: false
  end

  create_table "zip_exports", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.string   "zip_file_file_name"
    t.string   "zip_file_content_type"
    t.integer  "zip_file_file_size"
    t.datetime "zip_file_updated_at"
  end

  add_index "zip_exports", ["user_id"], name: "index_zip_exports_on_user_id", using: :btree

  add_foreign_key "activities", "experiments"
  add_foreign_key "activities", "my_modules"
  add_foreign_key "activities", "projects"
  add_foreign_key "activities", "users"
  add_foreign_key "asset_text_data", "assets"
  add_foreign_key "assets", "users", column: "created_by_id"
  add_foreign_key "assets", "users", column: "last_modified_by_id"
  add_foreign_key "checklist_items", "checklists"
  add_foreign_key "checklist_items", "users", column: "created_by_id"
  add_foreign_key "checklist_items", "users", column: "last_modified_by_id"
  add_foreign_key "checklists", "steps"
  add_foreign_key "checklists", "users", column: "created_by_id"
  add_foreign_key "checklists", "users", column: "last_modified_by_id"
  add_foreign_key "comments", "users"
  add_foreign_key "comments", "users", column: "last_modified_by_id"
  add_foreign_key "connections", "my_modules", column: "input_id"
  add_foreign_key "connections", "my_modules", column: "output_id"
  add_foreign_key "custom_fields", "teams"
  add_foreign_key "custom_fields", "users"
  add_foreign_key "custom_fields", "users", column: "last_modified_by_id"
  add_foreign_key "experiments", "users", column: "archived_by_id"
  add_foreign_key "experiments", "users", column: "created_by_id"
  add_foreign_key "experiments", "users", column: "last_modified_by_id"
  add_foreign_key "experiments", "users", column: "restored_by_id"
  add_foreign_key "my_module_groups", "experiments"
  add_foreign_key "my_module_groups", "users", column: "created_by_id"
  add_foreign_key "my_module_repository_rows", "users", column: "assigned_by_id"
  add_foreign_key "my_module_tags", "users", column: "created_by_id"
  add_foreign_key "my_modules", "experiments"
  add_foreign_key "my_modules", "my_module_groups"
  add_foreign_key "my_modules", "users", column: "archived_by_id"
  add_foreign_key "my_modules", "users", column: "created_by_id"
  add_foreign_key "my_modules", "users", column: "last_modified_by_id"
  add_foreign_key "my_modules", "users", column: "restored_by_id"
  add_foreign_key "notifications", "users", column: "generator_user_id"
  add_foreign_key "projects", "teams"
  add_foreign_key "projects", "users", column: "archived_by_id"
  add_foreign_key "projects", "users", column: "created_by_id"
  add_foreign_key "projects", "users", column: "last_modified_by_id"
  add_foreign_key "projects", "users", column: "restored_by_id"
  add_foreign_key "protocol_keywords", "teams"
  add_foreign_key "protocol_protocol_keywords", "protocol_keywords"
  add_foreign_key "protocol_protocol_keywords", "protocols"
  add_foreign_key "protocols", "my_modules"
  add_foreign_key "protocols", "protocols", column: "parent_id"
  add_foreign_key "protocols", "teams"
  add_foreign_key "protocols", "users", column: "added_by_id"
  add_foreign_key "protocols", "users", column: "archived_by_id"
  add_foreign_key "protocols", "users", column: "restored_by_id"
  add_foreign_key "report_elements", "assets"
  add_foreign_key "report_elements", "checklists"
  add_foreign_key "report_elements", "experiments"
  add_foreign_key "report_elements", "my_modules"
  add_foreign_key "report_elements", "projects"
  add_foreign_key "report_elements", "reports"
  add_foreign_key "report_elements", "results"
  add_foreign_key "report_elements", "steps"
  add_foreign_key "report_elements", "tables"
  add_foreign_key "reports", "projects"
  add_foreign_key "reports", "users"
  add_foreign_key "reports", "users", column: "last_modified_by_id"
  add_foreign_key "repositories", "users", column: "created_by_id"
  add_foreign_key "repository_columns", "users", column: "created_by_id"
  add_foreign_key "repository_date_values", "users", column: "created_by_id"
  add_foreign_key "repository_date_values", "users", column: "last_modified_by_id"
  add_foreign_key "repository_rows", "users", column: "created_by_id"
  add_foreign_key "repository_rows", "users", column: "last_modified_by_id"
  add_foreign_key "repository_text_values", "users", column: "created_by_id"
  add_foreign_key "repository_text_values", "users", column: "last_modified_by_id"
  add_foreign_key "result_assets", "assets"
  add_foreign_key "result_assets", "results"
  add_foreign_key "result_tables", "results"
  add_foreign_key "result_tables", "tables"
  add_foreign_key "result_texts", "results"
  add_foreign_key "results", "my_modules"
  add_foreign_key "results", "users"
  add_foreign_key "results", "users", column: "archived_by_id"
  add_foreign_key "results", "users", column: "last_modified_by_id"
  add_foreign_key "results", "users", column: "restored_by_id"
  add_foreign_key "sample_custom_fields", "custom_fields"
  add_foreign_key "sample_custom_fields", "samples"
  add_foreign_key "sample_groups", "teams"
  add_foreign_key "sample_groups", "users", column: "created_by_id"
  add_foreign_key "sample_groups", "users", column: "last_modified_by_id"
  add_foreign_key "sample_my_modules", "my_modules"
  add_foreign_key "sample_my_modules", "samples"
  add_foreign_key "sample_my_modules", "users", column: "assigned_by_id"
  add_foreign_key "sample_types", "teams"
  add_foreign_key "sample_types", "users", column: "created_by_id"
  add_foreign_key "sample_types", "users", column: "last_modified_by_id"
  add_foreign_key "samples", "sample_groups"
  add_foreign_key "samples", "sample_types"
  add_foreign_key "samples", "teams"
  add_foreign_key "samples", "users"
  add_foreign_key "samples", "users", column: "last_modified_by_id"
  add_foreign_key "step_assets", "assets"
  add_foreign_key "step_assets", "steps"
  add_foreign_key "step_tables", "steps"
  add_foreign_key "step_tables", "tables"
  add_foreign_key "steps", "protocols"
  add_foreign_key "steps", "users"
  add_foreign_key "steps", "users", column: "last_modified_by_id"
  add_foreign_key "tables", "users", column: "created_by_id"
  add_foreign_key "tables", "users", column: "last_modified_by_id"
  add_foreign_key "tags", "projects"
  add_foreign_key "tags", "users", column: "created_by_id"
  add_foreign_key "tags", "users", column: "last_modified_by_id"
  add_foreign_key "teams", "users", column: "created_by_id"
  add_foreign_key "teams", "users", column: "last_modified_by_id"
  add_foreign_key "tokens", "users"
  add_foreign_key "user_my_modules", "my_modules"
  add_foreign_key "user_my_modules", "users"
  add_foreign_key "user_my_modules", "users", column: "assigned_by_id"
  add_foreign_key "user_notifications", "notifications"
  add_foreign_key "user_notifications", "users"
  add_foreign_key "user_projects", "projects"
  add_foreign_key "user_projects", "users"
  add_foreign_key "user_projects", "users", column: "assigned_by_id"
  add_foreign_key "user_teams", "teams"
  add_foreign_key "user_teams", "users"
  add_foreign_key "user_teams", "users", column: "assigned_by_id"
  add_foreign_key "users", "teams", column: "current_team_id"
  add_foreign_key "wopi_actions", "wopi_apps"
  add_foreign_key "wopi_apps", "wopi_discoveries"
  add_foreign_key "zip_exports", "users"
end
