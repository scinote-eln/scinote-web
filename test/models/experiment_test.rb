require 'test_helper'
require 'helpers/archivable_model_test_helper'
require 'helpers/searchable_model_test_helper'

class ExperimentTest < ActiveSupport::TestCase
  should validate_length_of(:name)
    .is_at_least(Constants::NAME_MIN_LENGTH)
    .is_at_most(Constants::NAME_MAX_LENGTH)
  should validate_presence_of(:project)
  should validate_presence_of(:created_by)
  should validate_presence_of(:last_modified_by)
  should validate_length_of(:description)
    .is_at_most(Constants::TEXT_MAX_LENGTH)

  should have_db_column(:name).of_type(:string)
  should have_db_column(:description).of_type(:text)
  should have_db_column(:project_id).of_type(:integer)
  should have_db_column(:created_by_id).of_type(:integer)
  should have_db_column(:last_modified_by_id).of_type(:integer)
  should have_db_column(:archived).of_type(:boolean)
  should have_db_column(:archived_by_id).of_type(:integer)
  should have_db_column(:archived_on).of_type(:datetime)
  should have_db_column(:restored_by_id).of_type(:integer)
  should have_db_column(:restored_on).of_type(:datetime)
  should have_db_column(:created_at).of_type(:datetime)
  should have_db_column(:updated_at).of_type(:datetime)

  should belong_to(:project)
  should belong_to(:created_by)
  should belong_to(:last_modified_by)
  should belong_to(:archived_by)
  should belong_to(:restored_by)
  should have_many(:my_modules)
  should have_many(:my_module_groups)
end
