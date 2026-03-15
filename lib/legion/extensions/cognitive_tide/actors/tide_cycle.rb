# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module CognitiveTide
      module Actor
        class TideCycle < Legion::Extensions::Actors::Every
          def runner_class
            Legion::Extensions::CognitiveTide::Runners::CognitiveTide
          end

          def runner_function
            'tide_maintenance'
          end

          def time
            60
          end

          def run_now?
            false
          end

          def use_runner?
            false
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end
        end
      end
    end
  end
end
