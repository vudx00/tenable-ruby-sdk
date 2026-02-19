# frozen_string_literal: true

module Tenable
  class Client
    attr_reader :configuration

    def initialize(**options)
      @configuration = Configuration.new(**options)
      @connection = Connection.new(@configuration)
      freeze
    end

    def vulnerabilities
      Resources::Vulnerabilities.new(@connection)
    end

    def exports
      Resources::Exports.new(@connection)
    end

    def scans
      Resources::Scans.new(@connection)
    end

    def web_app_scans
      Resources::WebAppScans.new(@connection)
    end
  end
end
