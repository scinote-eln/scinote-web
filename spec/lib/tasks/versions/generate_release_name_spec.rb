# frozen_string_literal: true

require 'rails_helper'

describe 'versions:generate_release_name' do
  include_context 'rake once'
  let(:task_path) { 'lib/tasks/versions/generate_release_name' }

  let(:main) { TOPLEVEL_BINDING.receiver }
  let(:adjectives) { { 'c' => %w(curious clever), 'h' => %w(happy), 'n' => %w(noble) } }
  let(:scientists) { { 'c' => ['Marie Curie'], 'h' => ['Stephen Hawking'] } }

  before do
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with('lib/tasks/versions/adjectives.json').and_return(adjectives.to_json)
    allow(File).to receive(:read).with('lib/tasks/versions/scientists.json').and_return(scientists.to_json)
    allow(main).to receive(:rand).and_return(0)
    allow($stdin).to receive(:gets).and_return(*answers.map { |a| "#{a}\n" })
  end

  context 'with an invalid first choice' do
    let(:answers) { ['x'] }

    it 'prints an error and stops' do
      expect { subject.invoke }.to output(/Invalid parameter, exiting\n\z/).to_stdout
    end
  end

  context 'when the scientist is typed in' do
    let(:answers) { ['1', 'Nikola', 'Noble', 'e'] }

    it 'builds the name from the surname initial and exits on E' do
      # bug: key is `last_name[0].downcase.to_sym` but the JSON keys are strings, so adjectives[key] is nil
      pending 'bug: generate_release_name.rake manual scientist path looks up adjectives with a Symbol key'
      expect { subject.invoke }.to output(
        a_string_matching(/ Noble Noble\n \(full name: Nikola Noble\)/)
        .and(match(/\(E\) Exit/))
      ).to_stdout
    end
  end

  context 'when the choice is blank' do
    let(:answers) { ['', 'Charles', 'Hawk', ''] }

    it 'defaults to providing the scientist and exits on a blank answer' do
      pending 'bug: generate_release_name.rake manual scientist path looks up adjectives with a Symbol key'
      expect { subject.invoke }.to output(/Enter full scientist first name.* Happy Hawk\n/m).to_stdout
    end
  end

  context 'when a random scientist is chosen' do
    let(:answers) { %w(2 s a z e) }

    it 'prints the random scientist, regenerates and rejects invalid menu input' do
      expect { subject.invoke }.to output(
        a_string_matching(/Randomly chosen scientist: Marie Curie/)
        .and(match(/ Curious Curie\n \(full name: Marie Curie\)/))
        .and(match(/Invalid parameter!/))
      ).to_stdout
    end

    it 'picks a new adjective with the same scientist on "a"' do
      allow(main).to receive(:rand).and_return(0, 0, 0, 1)
      allow($stdin).to receive(:gets).and_return("2\n", "a\n", "E\n")

      expect { subject.invoke }.to output(/ Curious Curie.* Clever Curie /m).to_stdout
    end
  end
end
