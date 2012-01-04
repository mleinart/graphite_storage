module GraphiteStorage
  module Whisper
    module Constants
      module_function
      def calculate_size(format)
        # Only for numeric formats, String formats will raise a TypeError
        elements = 0
        format.each_char do |c|
          if c =~ /\d/
            elements += c.to_i - 1
          else
            elements += 1
          end
        end
        ([ 0 ] * elements).pack(format).length
      end

      def aggregation_method_from_code(code)
        AGGREGATION_METHOD_CODE[code]
      end

      def aggregation_code_from_name(name)
        AGGREGATION_METHOD_NAME[name]
      end

      def aggregation_method_exists?(name)
        AGGREGATION_METHOD_NAME.keys.include? name
      end

      AGGREGATION_METHOD_CODE = {
        1 => 'average',
        2 => 'sum',
        3 => 'last',
        4 => 'max',
        5 => 'min'
      }.freeze

      AGGREGATION_METHOD_NAME = AGGREGATION_METHOD_CODE.invert.freeze

      UNIT_MULTIPLIERS = {
        's' => 1,
        'm' => 60,
        'h' => 60 * 60,
        'd' => 60 * 60 * 24,
        'y' => 60 * 60 * 24 * 365,
      }.freeze

      TIMESTAMP_FORMAT = 'N'.freeze
      TIMESTAMP_SIZE = calculate_size(TIMESTAMP_FORMAT)
      VALUE_FORMAT = 'G'.freeze
      VALUE_SIZE = calculate_size(VALUE_FORMAT)
      POINT_FORMAT = 'NG'.freeze
      POINT_SIZE = calculate_size(POINT_FORMAT)
      METADATA_FORMAT = 'NNgN'.freeze
      METADATA_SIZE = calculate_size(METADATA_FORMAT)
      ARCHIVE_INFO_FORMAT = 'NNN'.freeze
      ARCHIVE_INFO_SIZE = calculate_size(ARCHIVE_INFO_FORMAT)
      ARCHIVE_INFO_OFFSET = METADATA_SIZE

      DEFAULT_WHISPER_OPTIONS = {
        :aggregation_method => 'average',
        :x_files_factor => 0.5
      }.freeze
    end
  end
end
