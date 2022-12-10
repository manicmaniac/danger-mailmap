# danger-mailmap

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
