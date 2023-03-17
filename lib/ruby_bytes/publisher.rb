# frozen_string_literal: true

module RubyBytes
  class Publisher
    attr_reader :compiler

    def self.call(...) = new(...).call

    def initialize(...)
      @compiler = Compiler.new(...)
    end

    def call
      require "net/http"
      require "json"

      token, account_id, template_id = ENV.fetch("RAILS_BYTES_TOKEN"), ENV.fetch("RAILS_BYTES_ACCOUNT_ID"), ENV.fetch("RAILS_BYTES_TEMPLATE_ID")

      uri = URI("https://railsbytes.com/api/v1/accounts/#{account_id}/templates/#{template_id}.json")

      request = Net::HTTP::Patch.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request.content_type = "application/json"

      tmpl = compiler.render
      request.body = JSON.dump(script: tmpl)

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end.then do |response|
        raise "Failed to publish template: #{response.code} — #{response.message}" unless response.code == "200"
      end
    end
  end
end
