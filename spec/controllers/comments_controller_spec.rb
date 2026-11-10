# frozen_string_literal: true

require 'rails_helper'

describe CommentsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { step: true, result_text: true }

  let(:step_record) { step }
  let(:result_record) { result_text.result }
  let(:commentables) do
    { 'Project' => project, 'MyModule' => my_module, 'Step' => step_record, 'Result' => result_record }
  end
  let(:activity_types) do
    {
      'Project' => %i(add_comment_to_project edit_project_comment delete_project_comment),
      'MyModule' => %i(add_comment_to_module edit_module_comment delete_module_comment),
      'Step' => %i(add_comment_to_step edit_step_comment delete_step_comment),
      'Result' => %i(add_comment_to_result edit_result_comment delete_result_comment)
    }
  end

  def build_comment(type, author = user)
    case type
    when 'Project' then create :project_comment, project: project, user: author
    when 'MyModule' then create :task_comment, my_module: my_module, user: author
    when 'Step' then create :step_comment, step: step_record, user: author
    when 'Result' then create :result_comment, result: result_record, user: author
    end
  end

  %w(Project MyModule Step Result).each do |type|
    context "with #{type} comments" do
      let(:commentable) { commentables[type] }
      let(:add_type) { activity_types[type][0] }
      let(:edit_type) { activity_types[type][1] }
      let(:delete_type) { activity_types[type][2] }

      it 'GET index returns the object data and comments html' do
        build_comment(type)
        get :index, params: { object_type: type, object_id: commentable.id }, format: :json
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body).to include('object_name', 'object_url', 'comment_addable', 'comments')
        expect(body['comment_addable']).to be true
        expect(body['object_name']).to be_present
      end

      it 'POST create saves the comment and logs an activity' do
        expect do
          post :create, params: { object_type: type, object_id: commentable.id, message: 'Hello there' },
                        format: :json
        end.to change { commentable.comments.count }.by(1)
                                                    .and change { Activity.where(type_of: add_type).count }.by(1)
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to have_key('html')
        expect(commentable.comments.last).to have_attributes(message: 'Hello there', user: user)
      end

      it 'POST create returns errors for an invalid comment' do
        expect do
          post :create, params: { object_type: type, object_id: commentable.id, message: '' }, format: :json
        end.not_to(change { Comment.count })
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to have_key('message')
      end

      it 'PUT update changes the message and logs an activity' do
        comment = build_comment(type)
        expect do
          put :update, params: { id: comment.id, message: 'Edited' }, format: :json
        end.to change { Activity.where(type_of: edit_type).count }.by(1)
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to have_key('html')
        expect(comment.reload.message).to eq 'Edited'
      end

      it 'PUT update returns errors for an invalid message' do
        comment = build_comment(type)
        put :update, params: { id: comment.id, message: '' }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(comment.reload.message).not_to eq ''
      end

      it 'DELETE destroy removes the comment and logs an activity' do
        comment = build_comment(type)
        expect do
          delete :destroy, params: { id: comment.id }, format: :json
        end.to change { Comment.count }.by(-1)
                                       .and change { Activity.where(type_of: delete_type).count }.by(1)
        expect(response).to have_http_status(:success)
      end

      it 'DELETE destroy reports an error when the comment cannot be destroyed' do
        comment = build_comment(type)
        allow_any_instance_of(Comment).to receive(:destroy).and_return(false)
        delete :destroy, params: { id: comment.id }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['message']).to eq I18n.t('comments.delete_error')
      end
    end
  end

  describe 'error handling' do
    it 'returns 404 for an unknown object type' do
      get :index, params: { object_type: 'Nothing', object_id: 1 }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for an unknown object id' do
      post :create, params: { object_type: 'Project', object_id: -1, message: 'x' }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for an unknown comment' do
      put :update, params: { id: -1, message: 'x' }, format: :json
      expect(response).to have_http_status(:not_found)
      delete :destroy, params: { id: -1 }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 403 when reading comments of an inaccessible project' do
      foreign = create :project
      get :index, params: { object_type: 'Project', object_id: foreign.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 when creating a comment on an inaccessible project' do
      foreign = create :project
      expect do
        post :create, params: { object_type: 'Project', object_id: foreign.id, message: 'x' }, format: :json
      end.not_to(change { Comment.count })
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 when editing a comment of an inaccessible project' do
      foreign = create :project
      comment = create :project_comment, project: foreign
      put :update, params: { id: comment.id, message: 'x' }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(comment.reload.message).not_to eq 'x'
      delete :destroy, params: { id: comment.id }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(Comment.exists?(comment.id)).to be true
    end
  end
end

describe CommentsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { team_role: :viewer, step: true, result_text: true }

  let(:author) { create :user }

  before do
    [project, experiment, my_module].each do |object|
      object.user_assignments.where(user: user).update_all(user_role_id: viewer_role.id)
      create_user_assignment(object, viewer_role, author)
    end
  end

  it 'allows a viewer to read comments' do
    create :project_comment, project: project, user: author
    get :index, params: { object_type: 'Project', object_id: project.id }, format: :json
    expect(response).to have_http_status(:success)
    expect(JSON.parse(response.body)['comment_addable']).to be false
  end

  it 'forbids a viewer from creating comments on every object type' do
    { 'Project' => project, 'MyModule' => my_module, 'Step' => step, 'Result' => result_text.result }
      .each do |type, object|
      expect do
        post :create, params: { object_type: type, object_id: object.id, message: 'nope' }, format: :json
      end.not_to(change { Comment.count })
      expect(response).to have_http_status(:forbidden)
    end
  end

  it 'forbids a viewer from editing or deleting comments of others' do
    comments = [
      create(:project_comment, project: project, user: author),
      create(:task_comment, my_module: my_module, user: author),
      create(:step_comment, step: step, user: author),
      create(:result_comment, result: result_text.result, user: author)
    ]
    comments.each do |comment|
      put :update, params: { id: comment.id, message: 'hacked' }, format: :json
      expect(response).to have_http_status(:forbidden)
      delete :destroy, params: { id: comment.id }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(comment.reload.message).not_to eq 'hacked'
    end
  end
end
