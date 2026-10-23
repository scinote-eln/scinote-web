# frozen_string_literal: true

require 'rails_helper'

describe 'sign_up_constraint:email_domain' do
  include_context 'rake file loaded once', 'sign_up_constraint'

  def constraint_definition
    ActiveRecord::Base.connection.select_value(
      "SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'email_must_be_company_email'"
    )
  end

  # DDL is transactional in PostgreSQL, so the per-example transaction removes the constraint again.
  it 'adds an escaped domain check constraint to users' do
    expect { rake_task('sign_up_constraint:email_domain').invoke('example.com') }
      .to output(/Created the following domain constraint: example\.com/).to_stdout

    expect(constraint_definition).to include('example\\.com')
  end

  it 'strips whitespace around the domain' do
    expect { rake_task('sign_up_constraint:email_domain').invoke('  scinote.net ') }.to output(/Created the following/).to_stdout

    expect(constraint_definition).to include('scinote\\.net')
    expect(constraint_definition).not_to include(' scinote')
  end

  it 'creates the constraint not validated so existing users are kept' do
    expect { rake_task('sign_up_constraint:email_domain').invoke('example.com') }.to output(/Created/).to_stdout

    validated = ActiveRecord::Base.connection.select_value(
      "SELECT convalidated FROM pg_constraint WHERE conname = 'email_must_be_company_email'"
    )
    expect(validated).to be(false)
  end

  # bug: lib/tasks/sign_up_constraint.rake:7 uses `return` inside the task block -> LocalJumpError
  pending 'bug: prints a hint and adds nothing when the domain is missing' do
    expect { rake_task('sign_up_constraint:email_domain').invoke }.to output(/Please add the email domain/).to_stdout

    expect(constraint_definition).to be_nil
  end

  pending 'bug: prints a hint when the domain is blank' do
    expect { rake_task('sign_up_constraint:email_domain').invoke('') }.to output(/Please add the email domain/).to_stdout

    expect(constraint_definition).to be_nil
  end
end

describe 'sign_up_constraint:remove_domain' do
  include_context 'rake file loaded once', 'sign_up_constraint'


  def constraint_exists?
    ActiveRecord::Base.connection.select_value(
      "SELECT 1 FROM pg_constraint WHERE conname = 'email_must_be_company_email'"
    ).present?
  end

  it 'removes an existing constraint' do
    expect { rake_task('sign_up_constraint:email_domain').invoke('example.com') }.to output(/Created/).to_stdout
    expect(constraint_exists?).to be(true)

    expect { rake_task('sign_up_constraint:remove_domain').invoke }
      .to output(/Email constraint has been removed/).to_stdout
    expect(constraint_exists?).to be(false)
  end

  it 'raises when there is no constraint to remove' do
    expect do
      expect { rake_task('sign_up_constraint:remove_domain').invoke }.to output.to_stdout
    end.to raise_error(StandardError)
  end
end
