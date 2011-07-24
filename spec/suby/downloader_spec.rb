require_relative '../spec_helper'

describe Suby::Downloader do
  show = 'How I Met Your Mother'
  season, episode = 3, 9
  title = 'Slapsgiving'
  ext = '.mkv'

  it 'parse correctly the file name' do
    [
      "#{show} #{season}x#{episode}#{ext}",
      "#{show} #{season}x#{"%.2d" % episode}#{ext}",
      "#{show} #{season}x#{episode} - #{title}#{ext}",
      "#{show} #{season}x#{"%.2d" % episode} - #{title}#{ext}"
    ].each { |filename|
      downloader = Suby::Downloader.new(filename)
      downloader.show.should == show
      downloader.season.should == season
      downloader.episode.should == episode
    }
  end
end
