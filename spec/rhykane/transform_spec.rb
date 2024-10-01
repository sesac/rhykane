# frozen_string_literal: true

require './lib/rhykane/transform'

require './lib/rhykane/jobs'
require './lib/rhykane/reader'
require './lib/rhykane/writer'

describe Rhykane::Transform do
  describe '.call' do
    it 'does transformation on rows and values given configuration. ' \
       'Keys are not automatically renamed. ' \
       'Values are not required to be transformed.' do
      cfg_path   = './spec/fixtures/rhykane.yml'
      cfg        = Rhykane::Jobs.load(cfg_path)[:map_b]
      input      = Rhykane::Reader.(tsv_data.open, **cfg[:source])
      output     = Rhykane::Writer.(out_io = StringIO.new, **cfg[:destination])
      expected   = CSV.read(tsv_data, **cfg.dig(:source, :opts)).to_a[1..]

      described_class.(input, output, **cfg[:transforms])
      result = CSV.parse(out_io.string)

      expect(result[1..]).to eq expected
      expect(result.first).to eq cfg.dig(:destination, :opts, :headers).map(&:to_s)
    end

    it 'does transformation on rows with provided runtime transform' do
      cfg_path   = './spec/fixtures/rhykane.yml'
      cfg        = Rhykane::Jobs.load(cfg_path)[:map_b]
      input      = Rhykane::Reader.(tsv_data.open, **cfg[:source])
      output     = Rhykane::Writer.(out_io = StringIO.new, **cfg[:destination])
      expected   = CSV.read(tsv_data, **cfg.dig(:source, :opts)).to_a[1..].map { |row| row << '1' }

      described_class.(input, output, **cfg[:transforms]) do |row|
        row[:wat] = 1

        row
      end
      result = CSV.parse(out_io.string)

      expect(result[1..]).to eq expected
      expect(result.first).to eq cfg.dig(:destination, :opts, :headers).map(&:to_s)
    end

    it 'sets default values when passed the set_default configuration' do
      cfg_path   = './spec/fixtures/rhykane.yml'
      cfg        = Rhykane::Jobs.load(cfg_path)[:map_b]
      input      = Rhykane::Reader.(tsv_data_empty_cells.open, **cfg[:source])
      output     = Rhykane::Writer.(out_io = StringIO.new, **cfg[:destination])
      expected   = [['asdf', 'Foo Bar', '100'], ['lkjh', 'Bar Foo', '20000'], %w[qwer default_value 99]]

      described_class.(input, output, **cfg[:transforms])
      result = CSV.parse(out_io.string)

      expect(result[1..]).to eq expected
    end
  end
end
