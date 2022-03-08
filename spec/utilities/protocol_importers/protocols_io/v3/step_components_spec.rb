# frozen_string_literal: true

require 'rails_helper'

describe ProtocolImporters::ProtocolsIo::V3::StepComponents do
  let(:components) do
    [
      { type_id: 1, source: { description: 'Description' } },
      { type_id: 3, something: 'second' },
      { type_id: 5, something: 'third' },
      { type_id: 6, source: { title: 'Title' } },
      { type_id: 1, something: 'last' },
      { type_id: 3 },
      { type_id: 4 },
      { type_id: 7 },
      { type_id: 8 }
    ]
  end

  let(:components_with_attachment) do
    components << { type_id: 23, source: { original_name: 'original_name', source: 'www.somewhere.com/smth.jpg' } }
  end

  let(:components_with_attachment_no_name) do
    components << { type_id: 23, source: { source: 'www.somewhere.com/smth.jpg' } }
  end

  describe 'self.get_component' do
    context 'when component is not avaiable' do
      it 'raise ArgumentError' do
        expect { described_class.get_component(-1, components) }.to raise_error(ArgumentError)
      end
    end

    context 'when component is avaiable' do
      it 'returns first component with the right type' do
        expect(described_class.get_component(1, components)).to be == components.select { |c| c[:type_id] == 1 }.first
      end
    end
  end

  describe 'self.name' do
    context 'when have name component' do
      it 'returns title value' do
        expect(described_class.name(components)).to be == 'Title'
      end
    end

    context 'when do not have name components' do
      it 'returns nil' do
        expect(described_class.name(components.reject { |e| e[:type_id] == 6 })).to be_nil
      end
    end
  end

  describe 'self.description' do
    context 'when have description component' do
      it 'returns description value' do
        expect(described_class.description(components)).to be == 'Description'
      end
    end

    context 'when do not have description components' do
      it 'returns nil' do
        expect(described_class.description(components.reject { |e| e[:type_id] == 1 })).to be_nil
      end
    end
  end

  describe 'self.description_components' do
    it 'returns all components avaiable for description' do
      # Description components are components with IDs: 3, 4, 7, 8, 9, 15, 17, 19, 20, 22, 24, 25, 26
      allow(described_class).to receive(:build_desc_component).and_return({})

      expect(described_class.description_components(components).size).to be == 5
    end
  end

  describe 'self.attachments' do
    context 'when have attachments with name' do
      it 'returns attachment with url and name' do
        expect(described_class.attachments(components_with_attachment))
          .to be == [{ name: 'original_name', url: 'www.somewhere.com/smth.jpg' }]
      end

      it 'returns attachment with url and generated name' do
        expect(described_class.attachments(components_with_attachment_no_name))
          .to be == [{ name: 'smth.jpg', url: 'www.somewhere.com/smth.jpg' }]
      end
    end

    context 'when do not have attachments' do
      it 'returns empty array' do
        expect(described_class.attachments(components)).to be_empty
      end
    end
  end

  describe 'self.build_desc_component' do
    context 'when not allowed component' do
      let(:wrong_component) { { type_id: -1 } }

      it { expect(described_class.build_desc_component(wrong_component)).to be_nil }
    end

    context 'when amount' do
      let(:amount) { { type_id: 3, source: { amount: 'amount', unit: 'unit', title: 'title' } } }
      let(:invalid_amount) { { type_id: 3, wrong_key: { amount: 'amount', unit: 'unit', title: 'title' } } }

      context 'when have valid amount components' do
        it do
          expect(described_class.build_desc_component(amount))
            .to eq(type: 'amount', value: 'amount', unit: 'unit', name: 'title')
        end
      end

      context 'when have missing source data' do
        # test usage of .dig function
        it 'returns hash with nil values' do
          expect(described_class.build_desc_component(invalid_amount).values.uniq).to eq ['amount', nil]
        end
      end
    end

    context 'when duration' do
      let(:duration) { { type_id: 4, source: { duration: 'duration', title: 'title' } } }

      it do
        expect(described_class.build_desc_component(duration)).to eq(type: 'duration', value: 'duration', name: 'title')
      end
    end

    context 'when link' do
      let(:link) { { type_id: 7, source: { link: 'link' } } }

      it do
        expect(described_class.build_desc_component(link)).to eq(type: 'link', source: 'link')
      end
    end

    context 'when software' do
      let(:software) do
        { type_id: 8, source: { name: 'name', link: 'link', repository: 'repo', developer: 'dev', os_name: 'osx' } }
      end
      let(:software_desc_component) do
        { type: 'software', name: 'name', source: 'link', details: { repository_link: 'repo',
                                                                     developer: 'dev',
                                                                     os_name: 'osx' } }
      end

      it do
        expect(described_class.build_desc_component(software)).to eq(software_desc_component)
      end
    end

    context 'when command' do
      let(:command) { { type_id: 15, source: { name: 'name', command: 'command', os_name: 'osx' } } }

      let(:command_desc_components) do
        { type: 'command', software_name: 'name', command: 'command', details: { os_name: 'osx' } }
      end

      it { expect(described_class.build_desc_component(command)).to eq(command_desc_components) }
    end

    context 'when result' do
      let(:result) { { type_id: 17, source: { body: 'body' } } }

      it { expect(described_class.build_desc_component(result)).to eq(type: 'result', body: 'body') }
    end

    context 'when warning' do
      let(:warning) { { type_id: 19, source: { body: 'body', link: 'link' } } }

      it do
        expect(described_class.build_desc_component(warning)).to eq(type: 'warning',
                                                                    body: 'body',
                                                                    details: { link: 'link' })
      end
    end

    context 'when reagent' do
      let(:reagent) do
        { type_id: 20, source: { name: 'name', url: 'url', sku: 'sku', linfor: 'linfor', mol_weight: 'mol_weight' } }
      end

      let(:reagent_desc_components) do
        { type: 'reagent', name: 'name', link: 'url', details: { catalog_number: 'sku',
                                                                 linear_formula: 'linfor',
                                                                 mol_weight: 'mol_weight' } }
      end

      it { expect(described_class.build_desc_component(reagent)).to eq(reagent_desc_components) }
    end

    context 'when gotostep' do
      let(:gotostep) { { type_id: 22, source: { title: 'title', step_guid: 'step_guid' } } }

      it do
        expect(described_class.build_desc_component(gotostep)).to eq(type: 'gotostep',
                                                                     value: 'title',
                                                                     step_id: 'step_guid')
      end
    end

    context 'when temperature' do
      let(:temperature) { { type_id: 24, source: { temperature: 'temp', unit: 'unit', title: 'title' } } }

      it do
        expect(described_class.build_desc_component(temperature)).to eq(type: 'temperature',
                                                                        value: 'temp',
                                                                        unit: 'unit',
                                                                        name: 'title')
      end
    end

    context 'when concentration' do
      let(:concentration) { { type_id: 25, source: { concentration: 'conc', unit: 'unit', title: 'title' } } }

      it do
        expect(described_class.build_desc_component(concentration)).to eq(type: 'concentration',
                                                                          value: 'conc',
                                                                          unit: 'unit',
                                                                          name: 'title')
      end
    end

    context 'when note' do
      let(:note) { { type_id: 26, source: { creator: { name: 'Author Name' }, body: 'body' } } }

      it do
        expect(described_class.build_desc_component(note)).to eq(type: 'note', author: 'Author Name', body: 'body')
      end
    end

    context 'when dataset' do
      let(:dataset) { { type_id: 9, source: { name: 'name', link: 'link' } } }

      it do
        expect(described_class.build_desc_component(dataset)).to eq(type: 'dataset', name: 'name', source: 'link')
      end
    end
  end
end
