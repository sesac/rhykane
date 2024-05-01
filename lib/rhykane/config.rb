# frozen_string_literal: true

require 'dry-validation'

class Rhykane
  class Config < Dry::Validation::Contract
    ConfigurationError = Class.new(ArgumentError)

    TransformsSchema = Dry::Schema.Params {
      optional(:row).filled(:hash)
      optional(:values).filled(:hash)
    }

    DataSchema = Dry::Schema.Params {
      required(:bucket).filled(:string)
      required(:key).filled(:string)
      required(:type).filled(:string)
      optional(:opts).filled(:hash)
    }

    params do
      optional(:transforms).hash(TransformsSchema)
      required(:source).hash(DataSchema)
      required(:destination).hash(DataSchema)
    end

    def call(*, **)
      contract = super

      return contract.to_h if contract.success?

      raise ConfigurationError, contract.errors.to_h
    end
  end
end
