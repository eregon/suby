require_relative '../spec_helper'

describe Suby::Downloader do
  Downloader = Suby::Downloader
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

  it 'finds the right show url'
end
