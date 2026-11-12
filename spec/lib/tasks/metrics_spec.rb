# frozen_string_literal: true

require 'rails_helper'

describe 'metrics:decoupling' do
  include_context 'rake once'

  it 'prints the number of erb and jsx files' do
    allow(Dir).to receive(:glob).with('**/*.erb') { |&blk| %w(a b c).each { |f| blk.call(f) } }
    allow(Dir).to receive(:glob).with('**/*.jsx') { |&blk| %w(a b).each { |f| blk.call(f) } }

    expect { subject.invoke }.to output(
      /Decoupling metrics.*Nr\. of ERB template files \(\*\.erb\):\n3\n.*Nr\. of React template files \(\*\.jsx\):\n2\n/m
    ).to_stdout
  end

  it 'prints zeros when there are no files' do
    allow(Dir).to receive(:glob).with(anything) { nil }

    expect { subject.invoke }.to output(/\(\*\.erb\):\n0\n.*\(\*\.jsx\):\n0\n/m).to_stdout
  end
end
