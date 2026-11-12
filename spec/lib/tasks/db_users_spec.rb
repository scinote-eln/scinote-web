# frozen_string_literal: true

require 'rails_helper'

describe 'db:load_users' do
  include_context 'rake once'
  let(:task_path) { 'lib/tasks/db_users' }

  let(:tmp_dir) { Dir.mktmpdir }
  let(:yaml_path) { File.join(tmp_dir, 'users.yml') }

  before { allow_any_instance_of(Team).to receive(:generate_template_project) }

  after { FileUtils.remove_entry(tmp_dir) }

  def write_yaml(hash)
    File.write(yaml_path, hash.to_yaml)
  end

  context 'when a file with users is given' do
    before do
      write_yaml(
        'user_1' => { 'full_name' => 'Rake Loaded', 'email' => 'rake.loaded@example.com',
                      'password' => 'Pass1234!word' },
        'user_2' => { 'full_name' => 'Rake Generated', 'email' => 'rake.generated@example.com' }
      )
    end

    it 'creates confirmed users, generates missing passwords and prints them' do
      expect { subject.invoke(yaml_path, 'false') }
        .to output(/Created users.*USER #\d+.*Full name: Rake Loaded.*Email: rake.loaded@example.com.*Password: Pass1234!word.*Email: rake.generated@example.com.*Password: [A-Za-z0-9]{8,}/m)
        .to_stdout

      user = User.find_by!(email: 'rake.loaded@example.com')
      expect(user.confirmed_at).to be_present
      expect(user.initials).to eq 'RL'
      expect(user.teams).to be_empty
    end

    it 'creates a private team per user when create_teams is "true"' do
      expect { subject.invoke(yaml_path, 'TRUE') }.to output(/Created users/).to_stdout

      user = User.find_by!(email: 'rake.generated@example.com')
      expect(user.teams.map(&:name)).to eq [Constants::DEFAULT_PRIVATE_WORKSPACE_NAME]
    end
  end

  context 'when the file has teams' do
    before { write_yaml('team_1' => { 'name' => 'Rake load team' }) }

    it 'creates a missing team' do
      expect { expect { subject.invoke(yaml_path) }.to output(/Created users/).to_stdout }
        .to change { Team.where(name: 'Rake load team').count }.by(1)
    end

    it 'reuses an already existing team with the same name' do
      create(:team, name: 'Rake load team')

      expect { expect { subject.invoke(yaml_path) }.to output.to_stdout }
        .not_to(change { Team.where(name: 'Rake load team').count })
    end
  end

  context 'when a user should join a team from the file' do
    before do
      write_yaml(
        'team_1' => { 'name' => 'Rake load team' },
        'user_1' => { 'full_name' => 'Rake Loaded', 'email' => 'rake.loaded@example.com',
                      'password' => 'Pass1234!word', 'teams' => 'team_1' }
      )
    end

    it 'adds the user to that team as owner' do
      expect { subject.invoke(yaml_path) }.to output(/USER #\d+/).to_stdout

      user = User.find_by!(email: 'rake.loaded@example.com')
      expect(user.teams.map(&:name)).to eq ['Rake load team']
    end
  end

  context 'when a user is invalid' do
    before do
      write_yaml('user_1' => { 'full_name' => 'Bad One', 'email' => 'not-an-email', 'password' => 'Pass1234!word' })
    end

    it 'reports the error and creates nothing' do
      expect { expect { subject.invoke(yaml_path) }.to output(/Error creating all users, transaction reverted/).to_stdout }
        .not_to(change { User.count })
    end
  end

  context 'when no file path is given' do
    it 'prints that no file was provided' do
      # bug: the task uses `return` inside the rake block which raises LocalJumpError
      pending 'bug: `return` inside the rake task block raises LocalJumpError instead of printing a message'
      expect { subject.invoke }.to output(/No file provided/).to_stdout
    end
  end
end

describe 'db:add_user' do
  include_context 'rake once'
  let(:task_path) { 'lib/tasks/db_users' }

  before do
    allow_any_instance_of(Team).to receive(:generate_template_project)
    allow($stdin).to receive(:gets).and_return(*answers.map { |a| "#{a}\n" })
  end

  context 'with all answers given' do
    let(:answers) { ['Added User', 'added.user@example.com', 'Pass1234!word', 'T', 'Add team A, Add team B'] }

    it 'creates the user with a private team and the extra teams' do
      expect { subject.invoke }
        .to output(/Successfully created user.*Email: added.user@example.com.*Password: Pass1234!word/m).to_stdout

      user = User.find_by!(email: 'added.user@example.com')
      expect(user.confirmed_at).to be_present
      expect(user.initials).to eq 'AU'
      expect(user.teams.map(&:name))
        .to contain_exactly(Constants::DEFAULT_PRIVATE_WORKSPACE_NAME, 'Add team A', 'Add team B')
    end
  end

  context 'with a private team only' do
    let(:answers) { ['Solo User', 'solo.user@example.com', 'Pass1234!word', 'T', ''] }

    it 'creates the user with the default private team' do
      expect { subject.invoke }.to output(/Successfully created user/).to_stdout

      expect(User.find_by!(email: 'solo.user@example.com').teams.map(&:name))
        .to eq [Constants::DEFAULT_PRIVATE_WORKSPACE_NAME]
    end
  end

  context 'with blank password and no teams' do
    let(:answers) { ['Plain User', 'plain.user@example.com', '', 'F', ''] }

    it 'generates a password and creates no teams' do
      expect { subject.invoke }.to output(/Password: [A-Za-z0-9]{8,}/).to_stdout

      expect(User.find_by!(email: 'plain.user@example.com').teams).to be_empty
    end
  end

  context 'with an invalid email' do
    let(:answers) { ['Bad User', 'nope', 'Pass1234!word', 'F', ''] }

    it 'reports that the transaction was reverted' do
      expect { expect { subject.invoke }.to output(/Error creating user, transaction reverted/).to_stdout }
        .not_to(change { User.count })
    end
  end
end
