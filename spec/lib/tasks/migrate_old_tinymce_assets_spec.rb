# frozen_string_literal: true

require 'rails_helper'

describe 'tinymce_assets:migrate_tinymce_assets' do
  include_context 'rake file loaded once', 'migrate_old_tinymce_assets'

  # The task is a one-off migration that queries tiny_mce_assets.step_id / result_text_id.
  # Those columns no longer exist in db/structure.sql, so the task cannot run any more.
  pending 'bug: lib/tasks/migrate_old_tinymce_assets.rake:9 queries dropped columns step_id/result_text_id' do
    expect { rake_task('tinymce_assets:migrate_tinymce_assets').invoke }.not_to raise_error
  end
end
