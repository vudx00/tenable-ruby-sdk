# frozen_string_literal: true

module Tenable
  module Models
    class Scan
      attr_reader :id, :uuid, :name, :status, :folder_id, :type,
                  :creation_date, :last_modification_date

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
