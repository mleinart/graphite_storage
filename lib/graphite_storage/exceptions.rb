module GraphiteStorage
  module Exceptions
    class FileNotFound < Errno::ENOENT; end
    class InvalidParameter < WhisperError; end
    class InvalidRange < WhisperError; end
    class EmptyArchive < WhisperError; end
  end
end
