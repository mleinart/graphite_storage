require 'rspec'
require 'tempfile'

$: << File.expand_path( File.join(File.dirname(__FILE__), '../lib') )

require 'graphite_storage'

DATA_DIR = File.expand_path( File.join(File.dirname(__FILE__), 'data') )

EMPTY_WHISPER_FILE = File.join(DATA_DIR, 'empty_2_archive_series.wsp')
RANDOM_WHISPER_FILE = File.join(DATA_DIR, 'random_2_archive_average_series.wsp')
RANDOM_WHISPER_FILE_START = 1000000020
SEQUENTIAL_WHISPER_FILE = File.join(DATA_DIR, 'sequential_2_archive_sum_series.wsp')
SEQUENTIAL_WHISPER_FILE_START = 1000000020

def clone_whisper_file(whisper_filename)
  orig_whisper_file = open(whisper_filename)
  temp_whisper_file = Tempfile.new('whisper')
  IO::copy_stream(orig_whisper_file, temp_whisper_file)
  orig_whisper_file.close
  temp_whisper_file
end
