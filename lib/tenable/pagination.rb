# frozen_string_literal: true

module Tenable
  class Pagination
    MAX_PAGE_SIZE = 200

    def initialize(limit: MAX_PAGE_SIZE, &fetcher)
      @limit = [limit, MAX_PAGE_SIZE].min
      @fetcher = fetcher
    end

    def each
      Enumerator::Lazy.new(raw_enumerator) { |yielder, item| yielder << item }
    end

    private

    def raw_enumerator
      Enumerator.new do |yielder|
        offset = 0
        loop do
          page = @fetcher.call(offset, @limit)
          items = extract_items(page)
          total = extract_total(page)

          items.each { |item| yielder << item }

          offset += @limit
          break if offset >= total || items.empty?
        end
      end
    end

    def extract_items(page)
      page[:items] || page['items'] || []
    end

    def extract_total(page)
      page[:total] || page['total'] || 0
    end
  end
end
