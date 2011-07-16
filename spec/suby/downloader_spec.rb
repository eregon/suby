require_relative '../spec_helper'

describe Suby::Downloader do
  Downloader = Suby::Downloader::TVSubtitles
  show = 'How I Met Your Mother'
  season, episode = 3, 9
  title = 'Slapsgiving'
  ext = '.mkv'
  file = "#{show} #{season}x#{episode} - #{title}#{ext}"

  it 'parse correctly the file name' do
    [
      "#{show} #{season}x#{episode}#{ext}",
      "#{show} #{season}x#{"%.2d" % episode}#{ext}",
      "#{show} #{season}x#{episode} - #{title}#{ext}",
      "#{show} #{season}x#{"%.2d" % episode} - #{title}#{ext}"
    ].each { |filename|
      downloader = Downloader.new(filename)
      downloader.show.should == show
      downloader.season.should == season
      downloader.episode.should == episode
    }
  end

  it 'finds the right show url' do
    Downloader.new(file).show_url.should == '/tvshow-110-3.html'
  end

  it 'finds the right episode url' do
    Downloader.new(file).episode_url.should == '/episode-7517-en.html'
    Downloader.new(file, :fr).episode_url.should == '/episode-7517-fr.html'
  end

  it 'finds the right subtitles url' do
    Downloader.new(file).subtitles_url.should == '/subtitle-9339.html'
    Downloader.new(file, :fr).subtitles_url.should == '/subtitle-31249.html'
  end

  it 'finds the right download url' do
    Downloader.new(file).download_url.should == '/files/How%20I%20Met%20Your%20Mother_3x09_en.zip'
    Downloader.new(file, :fr).download_url.should == '/files/How%20I%20Met%20Your%20Mother_3x09_fr.zip'
  end
end
