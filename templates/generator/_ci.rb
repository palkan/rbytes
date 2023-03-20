needs_ci = yes? "Would you like to configure GitHub Actions to test and publish your template?"

if needs_ci
  file ".github/workflows/test.yml", <%= code ".github/test.yml" %>
  file ".github/workflows/publish.yml", <%= code ".github/publish.yml" %>
end