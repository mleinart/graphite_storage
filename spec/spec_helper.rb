require 'rspec'
require 'tempfile'

$: << File.expand_path( File.join(File.dirname(__FILE__), '../lib') )

require 'graphite_storage'

DATA_DIR = File.expand_path( File.join(File.dirname(__FILE__), 'data') )

EMPTY_WSP = {
  :aggregation => 'average',
  :archives => 2,
  :file => File.join(DATA_DIR, 'empty_2_archive_series.wsp'),
  :intervals => [ 10, 20 ],
  :max_retention => 1200,
  :offsets => [ 40 ],
  :points => [ 60 ],
  :retentions => [ 600, 1200 ],
  :x_files_factor => 0.5
}
RANDOM_WSP = {
  :file => File.join(DATA_DIR, 'random_2_archive_average_series.wsp'),
  :start => 1000000020
}
SEQUENTIAL_WSP = {
  :file => File.join(DATA_DIR, 'sequential_2_archive_sum_series.wsp'),
  :start => 1000000020
}

SPARSE_WSP = {
  :file => File.join(DATA_DIR, 'sparse_2_archive_average_series.wsp'),
  :start => 1000000020,
  :spans => [ nil, 80 ]
}

def clone_whisper_file(whisper_filename)
  orig_whisper_file = open(whisper_filename)
  temp_whisper_file = Tempfile.new('whisper')
  IO::copy_stream(orig_whisper_file, temp_whisper_file)
  orig_whisper_file.close
  temp_whisper_file
end
