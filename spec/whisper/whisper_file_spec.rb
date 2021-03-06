require File.expand_path( File.join( File.dirname( __FILE__ ), '..', 'spec_helper.rb' ) )
require 'tempfile'

describe "GraphiteStorage::Whisper::WhisperFile" do
  it "should know its header information" do
    whisper_file = GraphiteStorage::Whisper.open(EMPTY_WSP[:file])

    whisper_file.archive_count.should == EMPTY_WSP[:archives]
    whisper_file.aggregation_method.should == EMPTY_WSP[:aggregation]
    whisper_file.max_retention.should == EMPTY_WSP[:max_retention]
    whisper_file.x_files_factor.should == EMPTY_WSP[:x_files_factor]
  end

  it "should detect whether or not the file exists" do
    no_whisper_file = GraphiteStorage::Whisper.open('this_file_does_not_exist')
    no_whisper_file.exists?.should be_false

    existing_whisper_file = GraphiteStorage::Whisper.open(EMPTY_WSP[:file])
    existing_whisper_file.exists?.should be_true
  end

  it "should be able to modify settable header values" do
    begin
      temp_file = clone_whisper_file(EMPTY_WSP[:file])
      whisper_file = GraphiteStorage::Whisper.open(temp_file)

      whisper_file.x_files_factor.should == EMPTY_WSP[:x_files_factor]
      whisper_file.x_files_factor = 0.1
      # Rounding is necessary because 0.1 doesnt store exactly as 0.1
      whisper_file.x_files_factor.round(1).should == 0.1
      whisper_file.aggregation_method.should == 'average'
      whisper_file.aggregation_method = 'sum'
      whisper_file.aggregation_method.should == 'sum'
    ensure
      temp_file.unlink
    end
  end

  it "should load the correct number of archives" do
    whisper_file = GraphiteStorage::Whisper.open(EMPTY_WSP[:file])
    whisper_file.archives.length.should == EMPTY_WSP[:archives]
  end

  it "should report the correct update interval" do
    whisper_file = GraphiteStorage::Whisper.open(EMPTY_WSP[:file])
    mock_archive = double('Archive')
    mock_archive.stub(:interval) { 10 }
    mock_archive.stub(:archive_count) { 1 }
    whisper_file.stub(:archives) { [ mock_archive ] }
    whisper_file.update_interval.should == 10
  end

  it "should return an empty series when no data points exist in the requested range" do
    whisper_file = GraphiteStorage::Whisper.open(EMPTY_WSP[:file])
    max_retention = whisper_file.max_retention
    mock_archive = double('Archive')
    mock_archive.stub(:interval) { 20 }
    mock_archive.stub(:retention) { max_retention }
    mock_archive.should_receive(:point_span).with(0, max_retention) { max_retention }
    mock_archive.should_receive(:read).with(0, max_retention) { [] }
    whisper_file.stub(:archives) { [ mock_archive ] }
    result = whisper_file[0,max_retention]
    result.empty?.should be_true
    result.should == []
  end

  it "should select the archive that matches the width of the requested range and has the best point span" do
    whisper_file = GraphiteStorage::Whisper.open(nil)
    whisper_file.stub(:archive_count) { 3 } # add another archive to the actual file
    whisper_file.stub(:max_retention) { 1200 }
    first_archive = double('Archive0')
    first_archive.stub(:interval) { 60 }
    first_archive.stub(:retention) { 60 }
    first_archive.stub(:point_span) { 60 }
    first_archive.stub(:read) { [0]*60 }
    second_archive = double('Archive1')
    second_archive.stub(:interval) { 240 }
    second_archive.stub(:retention) { 240 }
    second_archive.stub(:point_span) { 240 }
    second_archive.stub(:read) { [0]*240 }
    third_archive = double('Archive2')
    third_archive.stub(:interval) { 1200 }
    third_archive.stub(:retention) { 1200 }
    third_archive.stub(:point_span) { 1200 }
    third_archive.stub(:read) { [0]*1200 }
    whisper_file.stub(:archives) { [ first_archive, second_archive, third_archive ] }

    now = 1200
    whisper_file[now - 60,now].length.should == 60
    whisper_file[now - 240,now].length.should == 240
    whisper_file[now - 1200,now].length.should == 1200
  end

  it "should return a single value when accessed as an array with a single timestamp" do
    whisper_file = GraphiteStorage::Whisper.open(nil)
    whisper_file.stub(:archive_count) { 1 }
    whisper_file.stub(:max_retention) { 60 }
    mock_archive = double('Archive')
    mock_archive.stub(:interval) { 60 }
    mock_archive.stub(:retention) { 60 }
    mock_archive.stub(:point_span) { 60 }
    mock_archive.stub(:read) { [0] }
    whisper_file.stub(:archives) { [ mock_archive ] }
    data_point = whisper_file[0]
    data_point.should == 0
  end

  it "should return a valid time series when accessed as a slice" do
    whisper_file = GraphiteStorage::Whisper.open(nil)
    whisper_file.stub(:archive_count) { 1 }
    whisper_file.stub(:max_retention) { 60 }
    mock_archive = double('Archive')
    mock_archive.stub(:interval) { 60 }
    mock_archive.stub(:retention) { 60 }
    mock_archive.stub(:point_span) { 60 }
    mock_archive.stub(:read) {
      GraphiteStorage::Whisper::Series.new([0]*60, 60, 0, 60)
    }
    whisper_file.stub(:archives) { [ mock_archive ] }
    data_points = whisper_file[0,60]
    data_points.empty?.should be_false
    data_points.should == [0]*60
    data_points.begin.should == 0
    data_points.end.should == 60
  end

  it "should return a valid time series when accessed as a range" do
    whisper_file = GraphiteStorage::Whisper.open(nil)
    whisper_file.stub(:archive_count) { 1 }
    whisper_file.stub(:max_retention) { 60 }
    mock_archive = double('Archive')
    mock_archive.stub(:interval) { 60 }
    mock_archive.stub(:retention) { 60 }
    mock_archive.stub(:point_span) { 60 }
    mock_archive.stub(:read) {
      GraphiteStorage::Whisper::Series.new([0]*60, 60, 0, 60)
    }
    whisper_file.stub(:archives) { [ mock_archive ] }
    data_points = whisper_file[0..60]
    data_points.empty?.should be_false
    data_points.should == [0]*60
    data_points.begin.should == 0
    data_points.end.should == 60
  end

  it "should be able to create a new whisper file with the specified retentions and default settings" do
    temp_file = Tempfile.new('whisper')
    defaults = GraphiteStorage::Whisper::Constants::DEFAULT_WHISPER_OPTIONS
    whisper_file = GraphiteStorage::Whisper::WhisperFile.new(temp_file)
    whisper_file.create!('10:60', '60:20')
    whisper_file = GraphiteStorage::Whisper::WhisperFile.new(temp_file)
    whisper_file.aggregation_method.should == defaults[:aggregation_method]
    whisper_file.archive_count.should == 2
    whisper_file.max_retention.should == 1200
    whisper_file.x_files_factor.should == defaults[:x_files_factor]
  end

  it "should be able to create a new whisper file with the specified retentions and specified settings" do
    temp_file = Tempfile.new('whisper')
    whisper_file = GraphiteStorage::Whisper::WhisperFile.new(temp_file)
    whisper_file.create!('10:60', '60:20', :x_files_factor => 0.0, :aggregation_method => 'last')
    whisper_file = GraphiteStorage::Whisper::WhisperFile.new(temp_file)
    whisper_file.aggregation_method.should == 'last'
    whisper_file.archive_count.should == 2
    whisper_file.max_retention.should == 1200
    whisper_file.x_files_factor.should == 0.0
  end

  it "should reject creation of a whisper file with no archives" do
    temp_file = Tempfile.new('whisper')
    expect { GraphiteStorage::Whisper::WhisperFile.create(temp_file) }.to raise_error(GraphiteStorage::Exceptions::InvalidParameter)
  end

  it "should reject creation of a whisper file with intervals that dont evenly divide" do
    temp_file = Tempfile.new('whisper')
    expect { GraphiteStorage::Whisper::WhisperFile.create(temp_file, '3:10', '5:10') }.to raise_error(GraphiteStorage::Exceptions::InvalidParameter)
  end

  it "should reject creation of a whisper file with retentions that are not ordered smallest retention to largest" do
    temp_file = Tempfile.new('whisper')
    expect { GraphiteStorage::Whisper::WhisperFile.create(temp_file, '10:20', '20:5') }.to raise_error(GraphiteStorage::Exceptions::InvalidParameter)
  end

  it "should reject creation of a whisper file with intervals that are identical" do
    temp_file = Tempfile.new('whisper')
    expect { GraphiteStorage::Whisper::WhisperFile.create(temp_file, '10:20', '10:30') }.to raise_error(GraphiteStorage::Exceptions::InvalidParameter)
  end

  it "should reject creation of a whisper file where time retentions are identical" do
    temp_file = Tempfile.new('whisper')
    expect { GraphiteStorage::Whisper::WhisperFile.create(temp_file, '10:20', '20:10') }.to raise_error(GraphiteStorage::Exceptions::InvalidParameter)
  end
end
