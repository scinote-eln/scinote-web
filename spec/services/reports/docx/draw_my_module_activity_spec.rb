# frozen_string_literal: true

require 'rails_helper'

describe Reports::Docx::DrawMyModuleActivity do
  include_context 'docx_report'

  def create_activity(type, **extra)
    Activities::CreateActivityService.call(activity_type: type, owner: user, subject: my_module, team: team,
                                           project: project, message_items: { my_module: my_module.id }, **extra)
  end

  it 'returns false and draws nothing for a task without activities' do
    Activity.where(subject: my_module).delete_all
    expect(renderer.draw_my_module_activity(my_module)).to be(false)
    expect(heading_texts(4)).to be_empty
  end

  it 'draws the heading and one timestamped entry per activity' do
    Activity.where(subject: my_module).delete_all
    create_activity(:create_module)
    create_activity(:archive_module)
    first, second = Activity.where(subject: my_module).order(:id).to_a
    renderer.draw_my_module_activity(my_module)
    expect(heading_texts(4)).to eq(
      [I18n.t('projects.reports.elements.module_activity.name', my_module: my_module.name)]
    )
    texts = all_text
    expect(texts).to include(I18n.l(first.created_at, format: :full))
    expect(texts).to include(I18n.l(second.created_at, format: :full))
    expect(texts).to include(user.full_name)
  end

  it 'draws the stored message of old activities' do
    Activity.where(subject: my_module).delete_all
    create_activity(:create_module)
    activity = Activity.where(subject: my_module).order(:id).last
    activity.update_columns(message: 'Legacy activity text')
    allow_any_instance_of(Activity).to receive(:old_activity?).and_return(true)
    renderer.draw_my_module_activity(my_module)
    expect(all_text).to include('Legacy activity text')
  end
end
