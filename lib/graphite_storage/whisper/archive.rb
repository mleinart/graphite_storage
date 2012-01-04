require 'fcntl'

require 'graphite_storage/whisper/constants'

module GraphiteStorage
  module Whisper
    class Archive
      include Constants

      def initialize(path, archive_index)
        @path = path
        @archive_index = archive_index
      end

      def self.create(path, archive_index, offset, interval, points)
        archive = new(path, archive_index)
        archive.create!(offset, interval, points)
      end

      def clear!
        raw_points = ([0,0] * points).pack(POINT_FORMAT * points)
        File.open(@path, 'r+b') do |file|
          file.seek(offset)
          file.flock(File::LOCK_EX)
          file.write(raw_points)
        end
      end

      def create!(offset, interval, points)
        write_header({
          :offset => offset,
          :interval => interval,
          :points => points
        })
        clear!
        self
      end

      def interval
        header[:interval]
      end

      def offset
        header[:offset]
      end

      # Returns the number of non-nil points between from and to
      def point_span(from, to)
        return nil if first_timestamp == 0
        from = align_timestamp(from)
        to = align_timestamp(to)

        file = open(@path, 'rb')

        first_point = nil
        last_point = nil

        #XXX clean this shit up
        from.step(to, interval) do |timestamp|
          start_byte_offset = byte_offsets(timestamp, timestamp)[0]
          file.seek(start_byte_offset)
          raw_point = file.read(POINT_SIZE)
          point = raw_point.unpack(POINT_FORMAT)
          if point[0] == timestamp
            first_point = point
            break
          end
        end

        to.step(from, -interval) do |timestamp|
          start_byte_offset = byte_offsets(timestamp, timestamp)[0]
          file.seek(start_byte_offset)
          raw_point = file.read(POINT_SIZE)
          point = raw_point.unpack(POINT_FORMAT)
          if point[0] == timestamp
            last_point = point
            break
          end
        end

        file.close

        if first_point.nil? or last_point.nil?
          nil
        else
          last_point[0] - first_point[0]
        end
      end

      def points
        header[:points]
      end

      def read(from, to)
        return GraphiteStorage::Whisper::Series.new([], 0, 0, 0) if first_timestamp == 0
        from = align_timestamp(from)
        to = align_timestamp(to)

        start_byte_offset, end_byte_offset = byte_offsets(from, to)
        total_bytes = (end_byte_offset - start_byte_offset).abs
        archive_end_offset = offset + size

        file = open(@path, 'rb')

        if start_byte_offset > end_byte_offset
          file.seek(start_byte_offset)
          raw_points = file.read(total_bytes)
        else
          file.seek(start_byte_offset)
          raw_points = file.read(archive_end_offset - start_byte_offset)
          file.seek(offset)
          raw_points += file.read(end_byte_offset - offset)
        end
        file.close
        parsed_points = raw_points.unpack(POINT_FORMAT * total_points(from,to))

        expected_timestamp = from
        result = GraphiteStorage::Whisper::Series.new([], interval, from, to)

        # If timestamp doesnt match what it should be, it's nil
        parsed_points.each_slice(2) do |timestamp,value|
          if timestamp == expected_timestamp
            result << value
          else
            result << nil
          end
          expected_timestamp += interval
        end
        result
      end

      def retention
        interval * points
      end

      def size
        header[:points] * POINT_SIZE
      end

      def header
        @header ||= read_header
      end

      private
      def align_timestamp(timestamp)
        timestamp - timestamp % interval
      end

      def byte_offsets(from, to)
        time_offset = from - first_timestamp
        start_byte_distance = (time_offset/interval) * POINT_SIZE
        start_byte_offset = offset + start_byte_distance % size
        total_bytes = total_points(from, to) * POINT_SIZE
        end_byte_offset = offset + total_bytes % size
        [ start_byte_offset, end_byte_offset ]
      end

      def first_timestamp
        file = open(@path, 'rb')
        file.seek(offset)
        raw_timestamp = file.read(TIMESTAMP_SIZE)
        raw_timestamp.unpack(TIMESTAMP_FORMAT).first
      end

      def read_header
        file = open(@path, 'r')
        file.seek(ARCHIVE_INFO_OFFSET + ARCHIVE_INFO_SIZE * @archive_index)
        raw_archive = file.read(ARCHIVE_INFO_SIZE)
        file.close

        offset, interval, points = raw_archive.unpack(ARCHIVE_INFO_FORMAT)
        {
          :offset => offset,
          :interval => interval,
          :points => points
        }
      end

      def total_points(from, to)
        total_points = ((to - from) / interval) + 1
      end

      def write_header(new_header)
        raw_metadata = [
          new_header[:offset],
          new_header[:interval],
          new_header[:points]
        ].pack(ARCHIVE_INFO_FORMAT)

        File.open(@path, 'r+b') do |file|
          file.flock(File::LOCK_EX)
          file.seek(ARCHIVE_INFO_OFFSET + ARCHIVE_INFO_SIZE * @archive_index)
          file.write(raw_metadata)
        end
      end
    end
  end
end
