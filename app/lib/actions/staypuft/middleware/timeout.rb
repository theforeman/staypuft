module Actions
  module Staypuft
    module Middleware
      class Timeout < Dynflow::Middleware

        def plan(*args)
          pass(*args).tap do
            action.input[:timeout] ||= action.class::TIMEOUT
          end
        end

        def run(*args)
          assert_timeout_not_reached
          pass(*args)
        end

        private

        def assert_timeout_not_reached
          action.output[:timeout_start] ||= Time.now.to_i

          timeout_start = action.output[:timeout_start]
          now = Time.now.to_i
          timeout = action.input[:timeout]

          if now - timeout_start > timeout
            # clear timeout_start so that the action can be resumed/skipped
            action.output[:timeout_start] = nil
            fail(::Staypuft::Exception,
                 "You've reached the timeout set for this action. If the " +
                 "action is still ongoing, you can click on the " +
                 "\"Resume Deployment\" button to continue.")
          end
        end

      end
    end
  end
end
