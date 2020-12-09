# frozen_string_literal: true

require 'rails_helper'

describe Activity, type: :model do
  let(:activity) { build :activity }
  let(:old_activity) { build :activity, :old }

  it 'should be of class Activity' do
    expect(subject.class).to eq Activity
  end

  it 'is valid' do
    expect(activity).to be_valid
  end

  it 'is valid (old)' do
    expect(old_activity).to be_valid
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :my_module_id }
    it { should have_db_column :owner_id }
    it { should have_db_column :type_of }
    it { should have_db_column :message }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :project_id }
    it { should have_db_column :experiment_id }
  end

  describe 'Relations' do
    it { should belong_to(:project).optional }
    it { should belong_to(:experiment).optional }
    it { should belong_to(:my_module).optional }
    it { should belong_to :owner }
    it { should belong_to(:subject).optional }
  end

  describe 'Validations' do
    describe '#type_of' do
      it { is_expected.to validate_presence_of :type_of }
    end

    describe '#owner' do
      it { is_expected.to validate_presence_of :owner }
    end

    describe '#subject_type' do
      it { is_expected.to validate_inclusion_of(:subject_type).in_array(Extends::ACTIVITY_SUBJECT_TYPES) }
    end
  end

  describe '.old_activity?' do
    it 'returns true for old activity' do
      expect(old_activity.old_activity?).to be_truthy
    end
    it 'returns false for activity' do
      expect(activity.old_activity?).to be_falsey
    end
  end

  describe '.save' do
    it 'adds user to message items' do
      activity.save

      expect(activity.message_items).to include('user' => be_an(Hash))
    end
  end

  describe '.generate_breadcrumbs' do
    context 'when do not have subject' do
      it 'does not add breadcrumbs to activity' do
        expect { old_activity.generate_breadcrumbs }
          .not_to(change { activity.values['breadcrumbs'] })
      end
    end

    context 'when have subject' do
      it 'adds breadcrumbs to activity' do
        expect { activity.generate_breadcrumbs }
          .to(change { activity.values['breadcrumbs'] })
      end

      context 'when subject is a my_module' do
        let(:activity) { create :activity, subject: (create :my_module) }

        it 'has keys my_module, experiment, project and team' do
          activity.generate_breadcrumbs
          expect(activity.breadcrumbs)
            .to include(:my_module, :experiment, :project, :team)
        end
      end

      context 'when subject is a team' do
        let(:activity) { create :activity, subject: (create :team) }

        it 'has key team' do
          activity.generate_breadcrumbs
          expect(activity.breadcrumbs).to include(:team)
        end
      end
    end
  end
end
