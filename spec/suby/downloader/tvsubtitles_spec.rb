require_relative '../../spec_helper'

describe Suby::Downloader::TVSubtitles do
  file = 'How I Met Your Mother 3x9 - Slapsgiving.mkv'
  downloader = Suby::Downloader::TVSubtitles.new(file)
  downloader_fr = Suby::Downloader::TVSubtitles.new(file, :fr)

  it 'finds the right show url' do
    downloader.show_url.should == '/tvshow-110-3.html'
  end

  it 'finds the right episode url' do
    downloader.episode_url.should == '/episode-7517-en.html'
    downloader_fr.episode_url.should == '/episode-7517-fr.html'
  end

  it 'finds the right subtitles url' do
    downloader.subtitles_url.should == '/subtitle-9339.html'
    downloader_fr.subtitles_url.should == '/subtitle-31249.html'
  end

  it 'finds the right download url' do
    downloader.download_url.should == '/files/How%20I%20Met%20Your%20Mother_3x09_en.zip'
    downloader_fr.download_url.should == '/files/How%20I%20Met%20Your%20Mother_3x09_fr.zip'
  end

  it 'fails gently when the show does not exist' do
    d = Suby::Downloader::TVSubtitles.new('Not Existing Show 1x1.mkv')
    -> { d.show_url }.should throw_symbol(:downloader, "show not found")
  end

  it 'fails gently when the episode does not exist' do
    d = Suby::Downloader::TVSubtitles.new('How I Met Your Mother 3x99.mkv')
    -> { d.episode_url }.should throw_symbol(:downloader, "episode not found")
  end

  it 'fails gently when there is no subtitles available' do
    d = Suby::Downloader::TVSubtitles.new('Batman: The Animated Series 1x03.mkv')
    -> { d.subtitles_url }.should throw_symbol(:downloader, "no subtitle available")
  end
end
