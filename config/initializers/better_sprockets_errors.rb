# Monkey patch for sprockets so that we know which file gave us an error when
# compiling

module Sprockets
  module ProcessorUtils
    extend self
    alias_method :original_call_processor, :call_processor

    def call_processor processor, input
      original_call_processor processor, input
    rescue
      message = $!.message
      message += " (in #{input[:filename]})" unless message =~ /\ \(in\ /
      # Ignore these lines in the stack trace, the real problem is in your assets.
      raise $!.class.new message
    end
  end
end

