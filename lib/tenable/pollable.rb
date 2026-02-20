# frozen_string_literal: true

module Tenable
  # Shared polling behavior for resources that need to wait on async operations.
  #
  # Uses monotonic clock to avoid issues with system clock changes.
  module Pollable
    # Polls a block until it returns a truthy value or the timeout expires.
    #
    # @param timeout [Integer] maximum seconds to wait
    # @param poll_interval [Integer] seconds between polls
    # @param label [String] descriptive label for timeout error messages
    # @yield block that returns a truthy value when the operation is complete
    # @yieldreturn [Object, nil] truthy to stop polling, nil/false to continue
    # @return [Object] the truthy value returned by the block
    # @raise [Tenable::TimeoutError] if the timeout expires before the block returns truthy
    def poll_until(timeout:, poll_interval:, label:)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
      loop do
        if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          raise Tenable::TimeoutError, "#{label} timed out after #{timeout}s"
        end

        result = yield
        return result if result

        sleep(poll_interval)
      end
    end
  end
end
