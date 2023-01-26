# frozen_string_literal: true

require './lib/rhykane/transform'
require './lib/rhykane/jobs'

describe Rhykane::Transform do
  describe '.call' do
    it 'does transformation on rows and values given configuration. ' \
       'Keys are not automatically renamed. ' \
       'Values are not required to be transformed.' do
      cfg_path   = './spec/fixtures/rhykane.yml'
      cfg        = Rhykane::Jobs.load(cfg_path)[:map_b]
      input_path = Pathname('./spec/fixtures/data.tsv')
      input      = input_path.open
      output     = StringIO.new
      expected   = CSV.read(input_path, **cfg.dig(:source, :opts)).to_a[1..]

      described_class.(input, output, **cfg)
      result = CSV.parse(output.string)

      expect(result[1..]).to eq expected
      expect(result.first).to eq cfg.dig(:destination, :opts, :headers).map(&:to_s)
    end
  end
end
