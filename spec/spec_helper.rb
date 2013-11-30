require "./lib/helpers/parsable"
require "./lib/sections/vnum_section"
require "./lib/sections/line_by_line_object"

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end

def expect_one_error(item, message, printout=false)
  item.parse
  p item.errors if printout
  expect(item.errors.length).to eq(1)
  expect(item.errors.first.description).to eq(message)
end

shared_examples_for Section do
  it "ignores leading and trailing white space" do
    # Find the index of the first line break (after #SECTION_NAME)
    # to insert whitespace
    i = section.contents.index("\n")
    section.contents.insert(i+1, "\n"*10)
    section.contents << "\n"*10

    section.parse
    expect(section.errors).to be_empty
  end
end

shared_examples_for VnumSection do

  it "detects invalid vnums" do
    i = section.contents.match(/^#?\d+/).end(0) - 1
    section.contents[i] = "x"

    expect_one_error(section, VnumSection.err_msg(:invalid_vnum, section.id.upcase))
  end

  it "detects invalid text after vnums" do
    i = section.contents.match(/^#?\d+/).end(0) - 1
    section.contents.insert(i, " Oh hi there!")

    expect_one_error(section, VnumSection.err_msg(:invalid_after_vnum))
  end

  it "detects an empty section" do
    fake_section = VnumSection.new("##{section.id.upcase}\n#0\n")
    expect_one_error(fake_section, VnumSection.err_msg(:empty, fake_section.class))
  end

  it "detects a missing delimiter" do
    section.contents.slice!(section.class.delimiter)

    expect_one_error(section, section.delimiter_errors(:no_delimiter))
  end

  it "detects invalid text after the delimiter" do
    section.contents << "\nHey, babe."

    expect_one_error(section, section.delimiter_errors(:continues_after_delimiter))
  end

  it "detects duplicate vnums"  do
    m = section.contents.match(/#\d+.*?(?=#\d+)/m)
    first_line = m.pre_match.count("\n") + 2 # +2 because there's also the sliced off section name
    item = m[0]

    vnum = item[/(?<=#)\d+/].to_i
    i = section.contents.index(section.class.delimiter)
    section.contents.insert(i, item)

    # TODO: Make the line number (last arg) way less brittle
    expect_one_error(section, VnumSection.err_msg(:duplicate, section.child_class.name.downcase, vnum, first_line))
  end

end

shared_examples_for LineByLineObject do

  # test the expect method

  # test the oh shit, expect is going to fuck with rspec isn't it

  # fuuuuuuck yes it is

  # goddamn it

  it "detects an incomplete item"

  it "detects invalid blank lines inside an object"
end
