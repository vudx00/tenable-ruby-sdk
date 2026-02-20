# frozen_string_literal: true

module Tenable
  # Provides lazy, offset-based pagination over API list endpoints.
  #
  # Fetches pages on demand and yields individual items via {#each},
  # keeping memory usage constant regardless of total result count.
  # Includes Enumerable for standard collection methods.
  class Pagination
    include Enumerable

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

    # Iterates over all paginated items.
    #
    # @yield [item] yields each item
    # @return [Enumerator] if no block is given
    #
    # @example Iterate over all results
    #   paginator = Tenable::Pagination.new { |offset, limit| fetch_page(offset, limit) }
    #   paginator.each { |item| process(item) }
    #
    # @example Use Enumerable methods
    #   paginator.first(10)
    #   paginator.select { |item| item['severity'] > 2 }
    def each(&block)
      return enum_for(:each) unless block

      offset = 0
      loop do
        page = @fetcher.call(offset, @limit)
        items = extract_items(page)
        total = extract_total(page)

        items.each(&block)

        offset += @limit
        break if offset >= total || items.empty?
      end
    end

    # Returns a lazy enumerator over all paginated items.
    #
    # @return [Enumerator::Lazy]
    def lazy
      each.lazy
    end

    private

    def extract_items(page)
      page[:items] || page['items'] || []
    end

    def extract_total(page)
      page[:total] || page['total'] || 0
    end
  end
end
