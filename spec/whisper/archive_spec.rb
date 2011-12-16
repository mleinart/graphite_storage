require File.expand_path( File.join( File.dirname( __FILE__ ), '..', 'spec_helper.rb' ) )
require 'tempfile'

describe "GraphiteStorage::Whisper::Archive" do
  it "should know its header information" do
    archive = GraphiteStorage::Whisper::Archive.new(EMPTY_WHISPER_FILE, 0)

    archive.interval.should == 10
    archive.retention.should == 600
    archive.offset.should == 40
    archive.points.should == 60
  end

  it "should align timestamps to the nearest previous one" do
    archive = GraphiteStorage::Whisper::Archive.new(nil, 0)
    archive.stub(:interval) { 60 }

    interval = archive.interval
    aligned_timestamp = archive.align_timestamp(10 * interval + interval/2)
    aligned_timestamp.should == 10 * interval
  end
  #   archive = GraphiteStorage::Whisper::Archive.new(RANDOM_WHISPER_FILE, 0)

  #   interval = archive.interval
  #   retention = archive.retention

  #   data_points = archive.read()
  # end
end
