# frozen_string_literal: true

require 'pathname'

module FixtureHelper
  def fixtures_path
    Pathname.new('../fixtures').expand_path(__dir__)
  end

  def fixture(filename)
    fixtures_path.join(filename).to_s
  end

  def load_fixture(filename)
    File.read(fixture(filename))
  end

  def classes_in(*namespaces)
    namespaces
      .flat_map { |ns| ns.constants.map(&ns.public_method(:const_get)) }
      .select { |const| const.is_a? Class }
  end
end
