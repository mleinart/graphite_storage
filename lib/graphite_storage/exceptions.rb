module GraphiteStorage
  module Exceptions
    class FileNotFound < Errno::ENOENT; end
    class InvalidParameter < StandardError; end
    class InvalidRange < StandardError; end
    class EmptyArchive < StandardError; end
  end
end
