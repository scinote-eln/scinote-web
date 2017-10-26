require 'rails_helper'

RSpec.describe Datatables::DatatablesTeam, type: :model do
  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :name }
    it { should have_db_column :members }
    it { should have_db_column :role }
    it { should have_db_column :user_team_id }
    it { should have_db_column :user_id }
  end

  describe 'is readonly' do
    let(:user) { create :user }
    it do
      expect {
        Datatables::DatatablesTeam.create!(user_id: user.id)
      }.to raise_error(ActiveRecord::ReadOnlyRecord,
                       'Datatables::DatatablesTeam is marked as readonly')
    end
  end
end
