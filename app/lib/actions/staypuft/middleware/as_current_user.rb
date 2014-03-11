module Actions
  module Staypuft
    module Middleware
      class AsCurrentUser < Dynflow::Middleware

        def plan(*args)
          pass(*args).tap do
            raise 'no current user' unless Type? User.current, User
            action.input.update current_user_id: User.current.id
          end
        end

        def run(*args)
          as_current_user { pass(*args) }
        end

        def finalize
          as_current_user { pass }
        end

        private

        def current_user_id
          action.input.fetch(:current_user_id)
        end

        def as_current_user
          old          = User.current
          User.current = User.find current_user_id
          yield
        ensure
          User.current = old
        end

      end
    end
  end
end
