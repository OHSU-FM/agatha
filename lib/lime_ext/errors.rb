module LimeExt
  module Errors
    class LimeDataFiltersError < StandardError; end
    class LimeQueryError < StandardError; end
    class LimeMissingTable < StandardError; end
    class JSONRPCError < StandardError; end
    class InvalidCredentials < StandardError; end
  end
end
