require_relative '../../spec_helper'

describe Suby::Downloader::Addic7ed do
  file = 'The Glee Project 01x03.avi'
  downloader = Suby::Downloader::Addic7ed.new file

  it 'finds the right download url' do
    downloader.download_url.should be_start_with "/srtcache/The%20Glee%20Project"
  end
end
