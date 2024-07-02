# frozen_string_literal: true

require './lib/rhykane/functions'

describe Functions do
  let(:dummy_class) { Class.new { extend Functions } }

  it 'converts to json' do
    value = { test: "test" }
    result = dummy_class.to_json(value)

    expect { JSON.parse(result) }.to_not raise_error
  end

  it 'formats monthly period start & end' do
    value = '011222'
    start_args = { type: :start, date_format: '01%m%y' }
    result = dummy_class.parse_period(value, start_args)

    expect(Date.parse(result).day).to eq(1)
    expect(Date.parse(result).month).to eq(12)
    expect(Date.parse(result).year).to eq(2022)

    end_args = { type: :end, date_format: '01%m%y' }
    result = dummy_class.parse_period(value, end_args)

    expect(Date.parse(result).day).to eq(31)
    expect(Date.parse(result).month).to eq(12)
    expect(Date.parse(result).year).to eq(2022)
  end

  it 'formats ordinal quarterly period start & end' do
    value = 'Q4 2020'
    start_args = { type: :start, date_format: 'Q%m %Y', quarter_type: :ordinal }
    result = dummy_class.parse_period(value, start_args)

    expect(Date.parse(result).day).to eq(1)
    expect(Date.parse(result).month).to eq(10)
    expect(Date.parse(result).year).to eq(2020)

    end_args = { type: :end, date_format: 'Q%m %Y', quarter_type: :ordinal }
    result = dummy_class.parse_period(value, end_args)

    expect(Date.parse(result).day).to eq(31)
    expect(Date.parse(result).month).to eq(12)
    expect(Date.parse(result).year).to eq(2020)
  end

  it 'formats numeric quarterly period start & end' do
    value = '202209'
    start_args = { type: :start, date_format: '%Y%m', quarter_type: :numeric }
    result = dummy_class.parse_period(value, start_args)

    expect(Date.parse(result).day).to eq(1)
    expect(Date.parse(result).month).to eq(7)
    expect(Date.parse(result).year).to eq(2022)

    end_args = { type: :end, date_format: '%Y%m', quarter_type: :numeric }
    result = dummy_class.parse_period(value, end_args)

    expect(Date.parse(result).day).to eq(30)
    expect(Date.parse(result).month).to eq(9)
    expect(Date.parse(result).year).to eq(2022)
  end

  it 'formats durations given in seconds to iso8601 durations' do
    original_duration = '215.06612'
    result = dummy_class.seconds_to_iso(original_duration)

    expect(result).to eq('PT3M35S')

    original_duration = '3600'
    result = dummy_class.seconds_to_iso(original_duration)

    expect(result).to eq('PT1H')
  end

  it 'formats durations given in MM:SS and HH:MM:SS to iso8601 durations' do
    original_duration = '2:00'
    result = dummy_class.military_to_iso(original_duration)

    expect(result).to eq('PT0H2M0S')

    original_duration = '1:07:03'
    result = dummy_class.military_to_iso(original_duration)

    expect(result).to eq('PT1H7M3S')
  end

  it 'formats original to upcase' do
    original_track_isrc = 'ushm21323790'
    result = dummy_class.upcase(original_track_isrc)

    expect(result).to eq('USHM21323790')
  end

  it 'splits original on space and returns the first element' do
    original_release_date = '1978-01-01 00:00:00'
    result = dummy_class.split(original_release_date)

    expect(result).to eq('1978-01-01')
  end
end
