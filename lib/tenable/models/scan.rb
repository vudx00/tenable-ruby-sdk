# frozen_string_literal: true

module Tenable
  module Models
    # Represents a Tenable.io scan.
    class Scan
      # @return [Integer, nil] the scan ID
      attr_reader :id

      # @return [String, nil] the scan UUID
      attr_reader :uuid

      # @return [String, nil] the scan name
      attr_reader :name

      # @return [String, nil] current scan status
      attr_reader :status

      # @return [Integer, nil] the folder ID containing this scan
      attr_reader :folder_id

      # @return [String, nil] the scan type
      attr_reader :type

      # @return [Integer, nil] Unix timestamp of creation
      attr_reader :creation_date

      # @return [Integer, nil] Unix timestamp of last modification
      attr_reader :last_modification_date

      # @param data [Hash] raw API response hash
      def initialize(data)
        @id = data['id']
        @uuid = data['uuid']
        @name = data['name']
        @status = data['status']
        @folder_id = data['folder_id']
        @type = data['type']
        @creation_date = data['creation_date']
        @last_modification_date = data['last_modification_date']
      end
    end
  end
end
