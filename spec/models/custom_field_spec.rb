require 'rails_helper'

describe CustomField, type: :model do
  it 'should be of class CustomField' do
    expect(subject.class).to eq CustomField
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :name }
    it { should have_db_column :user_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :user_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :user }
    it { should belong_to :team }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should have_many :sample_custom_fields }
  end

  describe 'Should be a valid object' do
    before do
      @user = create :user, email: 'example_one@adsf.com'
      @team = create :team
      @samples_table = create :samples_table, user: @user, team: @team
    end

    it { should validate_presence_of :name }
    it { should validate_presence_of :user }

    it do
      should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
    end

    it do
      should validate_exclusion_of(:name).in_array(
        ['Assigned', 'Sample name', 'Sample type',
         'Sample group', 'Added on', 'Added by']
      )
    end

    it 'should have uniq name scoped on team' do
      create :custom_field, user: @user, team: @team
      custom_field_two = build :custom_field, user: @user, team: @team

      expect(custom_field_two).to_not be_valid
    end

    it 'should have uniq case sensitive name' do
      build_stubbed :custom_field, name: 'custom one', user: @user, team: @team
      cf = build :custom_field, name: 'CUSTOM ONE', user: @user, team: @team

      expect(cf).to be_valid
    end
  end
end
