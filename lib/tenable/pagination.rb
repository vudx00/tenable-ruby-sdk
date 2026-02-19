# frozen_string_literal: true

module Tenable
  # Provides lazy, offset-based pagination over API list endpoints.
  #
  # Fetches pages on demand and yields individual items via a lazy enumerator,
  # keeping memory usage constant regardless of total result count.
  class Pagination
    # @return [Integer] maximum items per page
    MAX_PAGE_SIZE = 200

    # Creates a new paginator.
    #
    # @param limit [Integer] items per page (capped at {MAX_PAGE_SIZE})
    # @yield [offset, limit] block that fetches a page of results
    # @yieldparam offset [Integer] the current offset
    # @yieldparam limit [Integer] the page size
    # @yieldreturn [Hash] a hash containing +"items"+ and +"total"+ keys
    def initialize(limit: MAX_PAGE_SIZE, &fetcher)
      @limit = [limit, MAX_PAGE_SIZE].min
      @fetcher = fetcher
    end

    # Returns a lazy enumerator over all paginated items.
    #
    # @return [Enumerator::Lazy] lazy enumerator yielding individual items
    #
    # @example Iterate over all results lazily
    #   paginator = Tenable::Pagination.new { |offset, limit| fetch_page(offset, limit) }
    #   paginator.each.first(10)
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
