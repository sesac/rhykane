# frozen_string_literal: true

require './lib/rhykane/transform'

describe Rhykane::Transform do
  describe '.call' do
    it 'does transformation on rows and values given configuration. ' \
       'Keys are not automatically renamed. ' \
       'Values are not required to be transformed.' do
      cfg_path   = './spec/fixtures/config.yml'
      cfg        = Rhykane::Config.load(cfg_path)[:map_b]
      input_path = Pathname('./spec/fixtures/data.tsv')
      input      = input_path.open
      output     = StringIO.new
      expected   = CSV.read(input_path, **cfg.dig(:reader, :opts)).to_a[1..]

      described_class.(input, output, **cfg)
      result = CSV.parse(output.string)

      expect(result[1..]).to eq expected
      expect(result.first).to eq cfg.dig(:writer, :opts, :headers).map(&:to_s)
    end
  end
end
