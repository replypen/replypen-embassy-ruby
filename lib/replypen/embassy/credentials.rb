# frozen_string_literal: true

require "json"

module ReplyPen
  module Embassy
    # The `credentials` map shared by the chat token claim (hub decision 20) and the analysis trigger
    # (hub decision 29): env name → string the host injects as workspace env, so the agent calls the
    # customer's own API as exactly the asserted user. Same rules the host checks, so an integrator
    # sees the error here instead of a host 400 far from its cause. Never logs or echoes a value.
    module Credentials
      KEY = /\A[A-Z][A-Z0-9_]{0,63}\z/
      MAX_ENTRIES = 8
      MAX_BYTES = 8 * 1024
      HINT = "Mint credentials as at most 8 string values under UPPER_SNAKE keys (no RC_ prefix), 8 KiB total."

      module_function

      # @return [Hash{String=>String}, nil] keys sorted (goldens and map-marshaling ports sign that
      #   order), or nil when absent/empty so the caller omits the key — never a null on the wire
      # @raise [Error] CREDENTIALS_INVALID
      def claim!(credentials)
        return nil if credentials.nil? || (credentials.respond_to?(:empty?) && credentials.empty?)

        raise invalid unless credentials.is_a?(Hash) && credentials.size <= MAX_ENTRIES

        claim = credentials.to_h { |key, value| [key.to_s, value] }.sort.to_h
        # NUL: an env value cannot carry one; the host refuses it rather than fail every container start.
        valid = claim.all? do |key, value|
          key.match?(KEY) && !key.start_with?("RC_") && value.is_a?(String) && !value.include?("\0")
        end
        raise invalid unless valid && JSON.generate(claim).bytesize <= MAX_BYTES

        claim
      end

      def invalid = Error.public("CREDENTIALS_INVALID", HINT)
    end
  end
end
