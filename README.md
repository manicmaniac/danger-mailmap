# danger-mailmap

[![Test](https://github.com/manicmaniac/danger-mailmap/actions/workflows/test.yml/badge.svg)](https://github.com/manicmaniac/danger-mailmap/actions/workflows/test.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/0b6932dadcec9c9b8484/maintainability)](https://codeclimate.com/github/manicmaniac/danger-mailmap/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/0b6932dadcec9c9b8484/test_coverage)](https://codeclimate.com/github/manicmaniac/danger-mailmap/test_coverage)

A Danger plugin to check if .mailmap has a canonical name of author and committer.

## Installation

```sh
gem install danger-mailmap
```

Or write the following code in your Gemfile.

```ruby
gem 'danger-mailmap'
```

## Usage

The easiest way to use is just add this to your Dangerfile:

```ruby
mailmap.check
```

If your repository has a mailmap file located in the place other than `.mailmap`, you can pass the path as argument.

```ruby
mailmap.check '/path/to/mailmap'
```

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.
