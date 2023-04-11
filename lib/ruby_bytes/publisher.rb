# frozen_string_literal: true

module RubyBytes
  class Publisher
    attr_reader :account_id, :token, :template_id

    def initialize(
      account_id: ENV.fetch("RAILS_BYTES_ACCOUNT_ID"),
      token: ENV.fetch("RAILS_BYTES_TOKEN"),
      template_id: ENV.fetch("RAILS_BYTES_TEMPLATE_ID")
    )
      @account_id = account_id
      @token = token
      @template_id = template_id
    end

    def call(template)
      require "net/http"
      require "json"

      path = "/api/v1/accounts/#{account_id}/templates/#{template_id}.json"
      data = JSON.dump(script: template)

      Net::HTTP.start("railsbytes.com", 443, use_ssl: true) do |http|
        http.patch(
          path,
          data,
          {
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{token}"
          }
        )
      end.then do |response|
        raise "Failed to publish template: #{response.code} — #{response.message}" unless response.code == "200"
      end
    end
  end
end
