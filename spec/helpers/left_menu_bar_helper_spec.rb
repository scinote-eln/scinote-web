# frozen_string_literal: true

require 'rails_helper'

describe LeftMenuBarHelper, type: :helper do
  def entry_named(translation_key)
    helper.left_menu_elements.find { |item| item[:name] == I18n.t(translation_key) }
  end

  def active_entry_names
    helper.left_menu_elements.select { |item| item[:active] }.map { |item| item[:name] }
  end

  describe '#left_menu_elements' do
    it 'lists the main navigation entries in order with their urls' do
      urls = helper.left_menu_elements.map { |item| item[:url] }

      expect(urls).to eq [
        dashboard_path, projects_path, repositories_path, storage_locations_path,
        equipment_bookings_path, forms_path, protocols_path, label_templates_path,
        reports_path, global_activities_path
      ]
    end

    it 'marks the projects entry active for experiments, modules and results pages' do
      %w(projects experiments my_modules results).each do |controller|
        allow(helper).to receive(:controller_name).and_return(controller)

        expect(entry_named('left_menu_bar.projects')[:active]).to be(true), "expected projects active for #{controller}"
      end
    end

    it 'marks exactly one entry active for the current controller' do
      allow(helper).to receive(:controller_name).and_return('protocols')

      expect(active_entry_names).to eq [I18n.t('left_menu_bar.protocol')]
    end

    it 'marks the protocol entry for result template and protocol repository row pages' do
      allow(helper).to receive(:controller_name).and_return('result_templates')
      expect(entry_named('left_menu_bar.protocol')[:active]).to be true

      allow(helper).to receive(:controller_name).and_return('protocol_repository_rows')
      expect(entry_named('left_menu_bar.protocol')[:active]).to be true
    end

    it 'marks no entry active on an unrelated page' do
      allow(helper).to receive(:controller_name).and_return('users')

      expect(active_entry_names).to eq []
    end

    it 'appends entries contributed by left_menu_*_extension private methods' do
      helper.define_singleton_method(:left_menu_acme_extension) do |menu|
        menu + [{ url: '/acme', name: 'Acme', icon: 'sn-icon-acme', active: false }]
      end
      helper.singleton_class.send(:private, :left_menu_acme_extension)

      entries = helper.left_menu_elements

      expect(entries.last).to eq(url: '/acme', name: 'Acme', icon: 'sn-icon-acme', active: false)
      expect(entries.size).to eq 11
    end
  end

  describe 'selection predicates' do
    {
      dashboard_are_selected?: ['dashboards'],
      repositories_are_selected?: ['repositories'],
      storage_locations_are_selected?: ['storage_locations'],
      equipment_bookings_are_selected?: ['equipment_bookings'],
      protocols_are_selected?: %w(protocols result_templates protocol_repository_rows),
      forms_are_selected?: ['forms'],
      label_templates_are_selected?: ['label_templates'],
      reports_are_selected?: ['reports'],
      activities_are_selected?: ['global_activities']
    }.each do |predicate, controllers|
      it "#{predicate} is true for #{controllers.join(', ')}" do
        controllers.each do |controller|
          allow(helper).to receive(:controller_name).and_return(controller)

          expect(helper.public_send(predicate)).to be(true), "expected #{predicate} for #{controller}"
        end
      end

      it "#{predicate} is false for an unrelated controller" do
        allow(helper).to receive(:controller_name).and_return('users')

        expect(helper.public_send(predicate)).to be(false)
      end
    end

    it 'settings_are_selected? is true for the settings controllers' do
      allow(helper).to receive(:controller_name).and_return('teams')

      expect(helper.settings_are_selected?).to be true
    end
  end
end
