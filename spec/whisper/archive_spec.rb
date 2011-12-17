require File.expand_path( File.join( File.dirname( __FILE__ ), '..', 'spec_helper.rb' ) )
require 'tempfile'

describe "GraphiteStorage::Whisper::Archive" do
  it "should know its header information" do
    archive = GraphiteStorage::Whisper::Archive.new(EMPTY_WSP[:file], 0)

    archive.interval.should == EMPTY_WSP[:intervals][0]
    archive.retention.should == EMPTY_WSP[:retentions][0]
    archive.offset.should == EMPTY_WSP[:offsets][0]
    archive.points.should == EMPTY_WSP[:points][0]
  end

  it "should align timestamps to the nearest previous one" do
    archive = GraphiteStorage::Whisper::Archive.new(RANDOM_WSP[:file], 1)

    interval = archive.interval
    aligned_timestamp = archive.align_timestamp(10 * interval + interval/2)
    aligned_timestamp.should == 10 * interval

    result = archive.read(
      RANDOM_WSP[:start] + interval/2,
      RANDOM_WSP[:start] + archive.retention - interval/2
    )
    result.begin.should == RANDOM_WSP[:start]
    result.end.should == RANDOM_WSP[:start] + archive.retention - archive.interval
  end

  it "should return a Series on a :read with the correct interval and time scope" do
    archive = GraphiteStorage::Whisper::Archive.new(RANDOM_WSP[:file], 1)
    result = archive.read(RANDOM_WSP[:start], RANDOM_WSP[:start] + archive.retention)
    result.class.should == GraphiteStorage::Whisper::Series
    result.interval.should == 20
    result.begin.should == RANDOM_WSP[:start]
    result.end.should == RANDOM_WSP[:start] + archive.retention
  end

  it "should return the correct point_span for a given set of timestamps" do
    archive = GraphiteStorage::Whisper::Archive.new(SPARSE_WSP[:file], 1)

    span = archive.point_span(SPARSE_WSP[:start], SPARSE_WSP[:start] + archive.retention)
    span.should == SPARSE_WSP[:spans][1]
  end
end
