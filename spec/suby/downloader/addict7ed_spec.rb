require_relative '../../spec_helper'

describe Suby::Downloader::Addic7ed do
  file = Path('The Big Bang Theory 01x01.avi')
  downloader = Suby::Downloader::Addic7ed.new file

  it 'finds the right subtitles' do
    begin
      downloader.subtitles[0..100].should include "If a photon is directed through a plane"
    rescue Suby::NotFoundError => e
      if e.message == "download exceeded"
        pending e.message
      else
        raise e
      end
    end
  end

  it 'fails gently when the show or the episode does not exist' do
    d = Suby::Downloader::Addic7ed.new(Path('Not Existing Show 1x1.mkv'))
    -> { d.download_url }.should raise_error(Suby::NotFoundError, "show/season/episode not found")
  end

  it 'fails gently when there is no subtitles available' do
    d = Suby::Downloader::Addic7ed.new(file, :zh)
    -> { p d.download_url.body }.should raise_error(Suby::NotFoundError, "no subtitles available")
  end
end
