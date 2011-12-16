require 'graphite_storage/whisper/whisper_file'

module GraphiteStorage
  module Whisper
    module_function
    def open(filename)
      WhisperFile.new(filename)
    end

    module_function
    def create(filename)
      WhisperFile.create(filename)
    end
  end
end
