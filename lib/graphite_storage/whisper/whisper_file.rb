require 'fcntl'

require 'graphite_storage/whisper/archive'
require 'graphite_storage/whisper/constants'
require 'graphite_storage/whisper/series'

module GraphiteStorage
  module Whisper
    class WhisperFile
      include Constants
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def [](*args)
        from, to = parse_range_args(*args)
        to.nil? ? read_series(from, from).first : read_series(from, to)
      end

      def []=(*args)
        data = args.pop
        from, to = parse_range_args(*args)
        to.nil? ? write_series(from, from).first : write_series(from, to)
      end

      def archive_count
        header[:archive_count]
      end

      def archives
        @archives ||= archive_count.times.collect do |archive_index|
          Archive.new(@path, archive_index)
        end
      end

      def aggregation_method
        aggregation_method_from_code(header[:aggregation_method])
      end

      def aggregation_method=(method)
        unless aggregation_method_exists? method
          raise InvalidParameter, "Invalid aggregation method specified: '#{method}'"
        end
        write_header(:aggregation_method => aggregation_code_from_name(method))
        @header = nil
      end

      def exists?
        File.exists? @path
      end

      def header
        @header ||= read_header
      end

      def max_retention
        header[:max_retention]
      end

      def update_interval
        archives.first.interval
      end

      def x_files_factor
        header[:x_files_factor]
      end

      def x_files_factor=(factor)
        unless (Float(factor).between?(0,1) rescue false)
          raise InvalidParameter, "Invalid x_files_factor value: '#{factor}'. x_files_factor must be a value between 0 and 1"
        end

        write_header(:x_files_factor => factor)
        @header = nil
      end

      private
      def parse_range_args(*args)
        unless args.length.between?(1,2)
          raise ArgumentError, "wrong number of arguments (#{args.size} for 1..2)"
        end

        if args.length == 1
          arg = args.first
          if arg.respond_to?(:begin) && arg.respond_to?(:end)
            from = arg.begin
            to = arg.end
          else
            from = arg
            to = nil
          end
        else
          from, to = args
        end

        begin
          from_epoch = Integer(from)
          to_epoch = to.nil? ? to : Integer(to)
        rescue ArgumentError => e
          raise InvalidParameter, "Cannot convert all values to epoch sends: #{args}"
        end
        unless to_epoch.nil?
          if from_epoch > to_epoch
            raise InvalidRange, "Invalid range specified: first time is greater than last time"
          elsif to_epoch - from_epoch > max_retention
            raise InvalidRange, "Invalid range specified: range is greater than the max retention (#{max_retention} points)"
          end
        end

        [ from_epoch, to_epoch ]
      end

      def read_header
        file = open(@path, 'rb')
        raw_metadata = file.read(METADATA_SIZE)
        aggregation_method, max_retention, x_files_factor, archive_count = raw_metadata.unpack(METADATA_FORMAT)
        file.close

        {
          :aggregation_method => aggregation_method,
          :max_retention => max_retention,
          :x_files_factor => x_files_factor,
          :archive_count => archive_count
        }
      end

      def read_series(from, to)
        point_range = to - from
        best_archive = nil

        # Select only the archives that can satisfy all of the points
        archives.select { |ar| ar.retention >= point_range }.reverse_each do |archive|
          timespan = archive.point_span(from, to)
          previous_timespan ||= timespan

          if previous_timespan >= timespan
            best_archive = archive
          else
            puts 'break'
            break
          end

          previous_timespan = timespan
        end

        if best_archive
          best_archive.read(from, to)
        else
          GraphiteStorage::Whisper::Series.new([], 0, 0, 0)
        end
      end

      def write_header(updated_values)
        new_header = header.merge(updated_values)
        raw_metadata = [
          new_header[:aggregation_method],
          new_header[:max_retention],
          new_header[:x_files_factor],
          new_header[:archive_count]
        ].pack(METADATA_FORMAT)

        File.open(@path, 'r+b') do |file|
          file.flock(File::LOCK_EX)
          file.write(raw_metadata)
        end
      end
    end
  end
end
