# frozen_string_literal: true

require 'rails_helper'

describe CommentHelper, type: :helper do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, user: user }
  let(:my_module) { create :my_module, experiment: experiment, created_by: user }
  let(:comment) { create :project_comment, project: project, user: user, message: 'old text' }

  before do
    user.update!(current_team_id: team.id)
    create_user_assignment(project, UserRole.find_predefined_owner_role, user, user)
    without_partial_double_verification do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:current_team).and_return(team)
    end
  end

  # The permission predicates are Canaid methods coming through method_missing; use the real ones
  describe '#comment_addable?' do
    it 'allows commenting on a project the user owns' do
      expect(helper.comment_addable?(project)).to be true
    end

    it 'is false for a project the user has no access to' do
      foreign = create :project, team: create(:team, created_by: create(:user)), created_by: create(:user)

      expect(helper.comment_addable?(foreign)).to be false
    end

    it 'is false for an unsupported object' do
      expect(helper.comment_addable?(team)).to be false
    end
  end

  describe '#comment_editable?' do
    it 'allows the author to edit a project comment' do
      expect(helper.comment_editable?(comment)).to be true
    end

    it 'is false for a comment type it does not know' do
      expect(helper.comment_editable?(double('comment', type: 'Other'))).to be false
    end
  end

  describe '#comment_update_helper' do
    before { allow(helper).to receive(:render) }

    it 'renders the auto linked message when no partial is given' do
      comment.message = 'new <b>text</b>'

      helper.comment_update_helper(comment, 'old text')

      expect(comment.reload.message).to eq 'new <b>text</b>'
      expect(helper).to have_received(:render).with(
        json: { comment: helper.custom_auto_link('new <b>text</b>', team: team, simple_format: true) },
        status: :ok
      )
    end

    it 'renders the validation errors when the comment is invalid' do
      comment.message = ''

      helper.comment_update_helper(comment, 'old text')

      expect(helper).to have_received(:render).with(
        json: { errors: comment.errors.to_hash(true) }, status: :unprocessable_entity
      )
      expect(comment.errors[:message]).to be_present
    end
  end
end
