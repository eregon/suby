require_relative '../../spec_helper'

describe Suby::Downloader::TVSubtitles do
  downloader = Downloader::TVSubtitles
  file = 'How I Met Your Mother 3x9 - Slapsgiving.mkv'

  it 'finds the right show url' do
    downloader.new(file).show_url.should == '/tvshow-110-3.html'
  end

  it 'finds the right episode url' do
    downloader.new(file).episode_url.should == '/episode-7517-en.html'
    downloader.new(file, :fr).episode_url.should == '/episode-7517-fr.html'
  end

  it 'finds the right subtitles url' do
    downloader.new(file).subtitles_url.should == '/subtitle-9339.html'
    downloader.new(file, :fr).subtitles_url.should == '/subtitle-31249.html'
  end

  it 'finds the right download url' do
    downloader.new(file).download_url.should == '/files/How%20I%20Met%20Your%20Mother_3x09_en.zip'
    downloader.new(file, :fr).download_url.should == '/files/How%20I%20Met%20Your%20Mother_3x09_fr.zip'
  end
end
