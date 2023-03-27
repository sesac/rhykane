# frozen_string_literal: true

require './lib/rhykane/functions'

describe Functions do
  let(:dummy_class) { Class.new { extend Functions } }

  it 'converts to json' do
    value = {test: "test"}
    result = dummy_class.to_json(value)

    expect { JSON.parse(result) }.to_not raise_error
  end

  it 'formats period start & end' do
    value = '011222'
    result = dummy_class.parse_period(value, :start)

    expect(Date.parse(result).day).to eq(1)

    result = dummy_class.parse_period(value, :end)

    expect(Date.parse(result).day).to eq(31)
  end
end
