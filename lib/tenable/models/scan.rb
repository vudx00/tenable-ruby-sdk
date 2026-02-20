# frozen_string_literal: true

module Tenable
  module Models
    # Represents a Tenable.io scan.
    Scan = Data.define(:id, :uuid, :name, :status, :folder_id, :type, :creation_date, :last_modification_date) do
      # Builds a Scan from a raw API response hash.
      #
      # @param data [Hash] raw API response hash with string keys
      # @return [Scan]
      def self.from_api(data)
        data = data.transform_keys(&:to_sym)
        new(
          id: data[:id],
          uuid: data[:uuid],
          name: data[:name],
          status: data[:status],
          folder_id: data[:folder_id],
          type: data[:type],
          creation_date: data[:creation_date],
          last_modification_date: data[:last_modification_date]
        )
      end
    end
  end
end
