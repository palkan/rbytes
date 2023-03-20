# frozen_string_literal: true

require "test_helper"

class ExampleTest < GeneratorTestCase
  template <<~'CODE'
    <%%= include "example" %>
  CODE

  def test_name
    run_generator do |output|
      assert_line_printed(
        output,
        "Hey from the included template!"
      )
    end
  end
end
