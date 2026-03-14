# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveTide
      module Helpers
        class TidalPool
          attr_reader :id, :domain, :capacity, :evaporation_count

          def initialize(domain:, capacity: 20)
            raise ArgumentError, 'capacity must be positive' unless capacity.positive?

            @id               = SecureRandom.uuid
            @domain           = domain.to_s
            @capacity         = capacity
            @items            = []
            @evaporation_count = 0
            @created_at = Time.now.utc
          end

          # Deposit an idea item into the pool; silently drops if full
          def deposit(item)
            return false if full?

            @items << { content: item, deposited_at: Time.now.utc, id: SecureRandom.uuid }
            true
          end

          # Harvest all items from the pool, clearing it; returns the harvested items
          def harvest!
            harvested = @items.dup
            @items.clear
            harvested
          end

          # Apply evaporation: remove a proportion of items (oldest first)
          def evaporate!(rate = Constants::POOL_EVAPORATION_RATE)
            clamped_rate = rate.clamp(0.0, 1.0)
            count_to_remove = (@items.size * clamped_rate).ceil
            removed = @items.shift(count_to_remove)
            @evaporation_count += removed.size
            removed.size
          end

          def empty?
            @items.empty?
          end

          def full?
            @items.size >= @capacity
          end

          # Depth as a fraction of capacity: item_count / capacity
          def depth
            return 0.0 if @capacity.zero?

            (@items.size.to_f / @capacity).round(10)
          end

          def items
            @items.dup
          end

          def size
            @items.size
          end

          def to_h
            {
              id:                @id,
              domain:            @domain,
              capacity:          @capacity,
              size:              @items.size,
              depth:             depth,
              evaporation_count: @evaporation_count,
              created_at:        @created_at
            }
          end
        end
      end
    end
  end
end
