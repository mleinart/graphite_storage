require File.expand_path( File.join( File.dirname( __FILE__ ), '..', 'spec_helper.rb' ) )

describe "GraphiteStorage::Whisper::Series" do
  before do
    now = Time.now.to_i
    @series = GraphiteStorage::Whisper::Series.new([0,1,2,3,4,5,6], 1, now, now + 6)
  end

  it "should enumerate over data points with :each" do
    counter = 0
    @series.each do |data_point|
      data_point.should == counter
      counter += 1
    end
  end

  it "should return a valid enumerator when :each is called" do
    enumerator = @series.each
    7.times do |i|
      enumerator.next.should == i
    end
    expect { enumerator.next }.to raise_error(StopIteration)
  end

  it "should enumerate over data points and timestamps with :each_pair" do
    counter = 0
    timestamp_counter = @series.begin
    @series.each_pair do |data_point,timestamp|
      data_point.should == counter
      timestamp.should == timestamp_counter
      counter += 1
      timestamp_counter += 1
    end
  end
end
