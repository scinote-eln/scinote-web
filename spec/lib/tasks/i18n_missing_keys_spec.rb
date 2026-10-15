# frozen_string_literal: true

require 'rails_helper'

describe 'i18n:missing_keys' do
  include_context 'rake once'
  let(:task_path) { 'lib/tasks/i18n_missing_keys' }

  around do |example|
    locale = I18n.locale
    example.run
  ensure
    I18n.locale = locale
  end

  def stub_i18n(locales, translations, translate_impl)
    allow(I18n).to receive(:available_locales).and_return(locales)
    allow(I18n.backend).to receive(:init_translations)
    allow(I18n.backend).to receive(:translations).and_return(translations)
    allow(I18n).to receive(:translate).and_wrap_original do |orig, key, **opts|
      key.is_a?(String) ? translate_impl.call(key, **opts) : orig.call(key, **opts)
    end
  end

  it 'lists keys missing from some locales' do
    translations = { en: { a: { b: 'x', c: 'y' }, d: 'z' }, fr: { a: { b: 'x' } } }
    impl = lambda do |key, **|
      raise I18n::MissingTranslationData.new(I18n.locale, key) if I18n.locale == :fr && key != 'a.b'

      'ok'
    end
    stub_i18n(%i[en fr], translations, impl)

    expect { subject.invoke }.to output(
      "2 locales available: en and fr\n" \
      "3 unique keys found.\n" \
      "2 keys are missing from one or more locales:\n" \
      "'a.c': Missing from fr\n" \
      "'d': Missing from fr\n"
    ).to_stdout
  end

  it 'ignores keys with missing interpolation arguments and reports nothing missing' do
    stub_i18n([:en], { en: { greet: 'Hi %{name}' } },
              ->(key, **) { raise I18n::MissingInterpolationArgument.new(:name, {}, key) })

    expect { subject.invoke }.to output(
      "1 locale available: en\n1 unique key found.\n0 keys are missing from one or more locales:\n"
    ).to_stdout
  end

  it 'uses the singular wording when exactly one key is missing' do
    stub_i18n(%i[en fr], { en: { only: 'x' }, fr: {} },
              ->(key, **) { I18n.locale == :fr ? raise(I18n::MissingTranslationData.new(:fr, key)) : 'ok' })

    expect { subject.invoke }.to output(/1 key is missing from one or more locales:\n'only': Missing from fr\n/).to_stdout
  end
end

describe 'i18n:unused_keys' do
  include_context 'rake once'
  let(:task_path) { 'lib/tasks/i18n_missing_keys' }

  let(:main) { TOPLEVEL_BINDING.receiver }
  def pending_unused_keys_bug
    # bug: Process::Status has no `successful?` (it is `success?`), so the task always raises NoMethodError
    pending 'bug: i18n_missing_keys.rake `$CHILD_STATUS.successful?` does not exist on Process::Status'
  end

  let(:yaml) { { 'en' => { 'used' => { 'key' => 'x' }, 'lonely' => 'y' } } }

  before do
    allow(Dir).to receive(:entries).with('config/locales').and_return(['tasks.en.yml', 'tasks.de.yml', 'readme.txt'])
    allow(YAML).to receive(:load_file).with('config/locales/tasks.en.yml').and_return(yaml)
    allow(YAML).to receive(:load_file).with('config/locales/tasks.de.yml').and_return('de' => { 'dekey' => 'z' })
    # the task shells out to grep; fake it so that only 'used.key' is "found"
    allow(main).to receive(:`) do |cmd|
      cmd.include?('used.key') ? `true` : `false`
    end
  end

  it 'lists the keys without a grep hit for the default locale' do
    pending_unused_keys_bug
    expect { subject.invoke }.to output(
      "Following keys are unused (for locale en):\n  lonely\n"
    ).to_stdout
  end

  it 'works for a different locale given as argument' do
    pending_unused_keys_bug
    expect { subject.invoke('de') }.to output(
      "Following keys are unused (for locale de):\n  dekey\n"
    ).to_stdout
  end

  it 'reports that nothing is unused when every key is found' do
    pending_unused_keys_bug
    allow(main).to receive(:`) { `true` }

    expect { subject.invoke }.to output("No unused keys found!\n").to_stdout
  end
end
