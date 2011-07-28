require_relative '../../spec_helper'

describe Suby::Downloader::Addic7ed do
  file = 'The Glee Project 01x03.avi'
  downloader = Suby::Downloader::Addic7ed.new file

  it 'finds the right download url' do
    begin
      downloader.download_url.should be_start_with "/srtcache/The%20Glee%20Project"
    rescue Suby::NotFoundError => e
      if e.message == "download exceeded"
        pending e.message
      else
        raise e
      end
    end
  end

  it 'fails gently when the show or the episode does not exist' do
    d = Suby::Downloader::Addic7ed.new('Not Existing Show 1x1.mkv')
    -> { d.download_url }.should raise_error(Suby::NotFoundError, "show/season/episode not found")
  end

  it 'fails gently when there is no subtitles available' do
    d = Suby::Downloader::Addic7ed.new(file, :es)
    -> { p d.download_url }.should raise_error(Suby::NotFoundError, "no subtitle available")
  end
end
