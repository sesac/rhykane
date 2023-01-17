# rhykane
Tool for mapping/normalizing data

## Installation

Add the following to your Gemfile

```console
gem 'rhykane', git: 'https://github.com/sesac/rhykane.git', tag: 'v0.1.0'
```

## Usage

``` ruby
require 'rhykane'

# explicit config
Rhykane.(
  transforms: {
    row: { accept_keys: %i[record_id title amount] }
  },
  source: {
    bucket: "foo"
    key: "data.tsv"
    type: "csv"
    opts: { col_sep: "\t", headers: true }
  },
  destination: {
    bucket: "bar"
    key: "data.csv"
    type: "csv"
    opts: { write_headers: false }
  }
)

# config from file
# location assumed to be ./config/rhykane.yml
Rhykane.for(:mapping_job).()
```

```yml
# sample yml config
mapping_job:
  transforms:
    row:
      rename_keys:
        id: :record_id
        desc: :title
        total: :amount
      accept_keys:
        - :record_id
        - :title
        - :amount
    values:
      amount:
        - :to_decimal
        - :to_float
  source:
    bucket: "foo"
    key: "data.tsv"
    type: "csv"
    opts:
      col_sep: "\t"
      headers: true
  destination:
    bucket: "bar"
    key: "data.csv"
    type: "csv"
    opts:
      write_headers: false
```

`Rhykane` will validate the inputs, stream data located at the source, transform it, and write the transformed data to
the destination.

## Transforms

`Rhykane` transformations are powered by the [`dry-transformer`](https://dry-rb.org/gems/dry-transformer/0.1/) gem. Any coercions, array transformations, or hash transformations provided by `dry-transformer` are supported by `rhykane`.

## Sources/Destinations

Sources and destinations are assumed to be objects in S3. The parameters `:bucket` and `:key` indicate the location of the object in S3.

Two types are supported, `:csv` and `:json`. 

### CSV

Options for the `:csv` type are anything supported by [`CSV.new`](https://ruby-doc.org/3.2.0/stdlibs/csv/CSV.html#method-c-new). This includes reading and writing.

### JSON

`:json` types are assumed to be [`JSON Lines`](https://jsonlines.org/) documents, where each line contains a distinct, complete JSON record. Options for reading JSON are anything supported by [`JSON.parse`](https://ruby-doc.org/3.2.0/exts/json/JSON.html#method-i-parse). No separate options are supported for writing JSON data.

## Configuration files

`Rhykane` supports configuring multiple, distinct, transformation jobs in a `YAML` document. If used, this configuration document is assumed to exist at the path `./config/rhykane.yml` in your project. You can override the directory where this file exists when executing `.for`, e.g. `Rhykane.for(:my_job, 'alternate/configuration/directory')`, but the filename of `rhykane.yml` cannot be overridden.

A configuration file is not required for usage. Explicit invocation through the `.call` method with a configuration hash is also supported. See the first example above.
