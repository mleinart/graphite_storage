module GraphiteStorage
  module Whisper
    class Series < ::Array
      include Enumerable

      attr_reader :interval
      attr_reader :begin
      attr_reader :end

      def initialize(data, interval, first_timestamp, last_timestamp)
        @interval = interval
        @begin = first_timestamp
        @end = last_timestamp
        super(data) if data
      end

      def each_pair(&block)
        if block_given?
          timestamp = @begin
          each do |point|
            yield [ point, timestamp ]
            timestamp += interval
          end
        else
          Enumerator.new(self, :each_pair)
        end
      end
    end
  end
end
