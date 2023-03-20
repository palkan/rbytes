# frozen_string_literal: true

<%= include "details" %>

inside(root_dir) do
  <%= include "scaffold", indent: 2 %>
  <%= include "testing", indent: 2 %>
  <%= include "ci", indent: 2 %>
end
