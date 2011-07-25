require_relative '../spec_helper'

describe Suby::Downloader do
  show = 'How I Met Your Mother'
  season, episode = 3, 9
  title = 'Slapsgiving'
  ext = '.mkv'
  dot_show = show.tr(' ', '.')
  und_show = show.tr(' ', '_')

  [
    "#{show} #{season}x#{episode}",
    "#{show} #{season}x#{"%.2d" % episode}",
    "#{show} #{season}x#{episode} - #{title}",
    "#{show} #{season}x#{"%.2d" % episode} - #{title}",
    "#{dot_show}.s0309",
    "#{dot_show}.0309",
    "#{dot_show}.3x09",
    "#{dot_show}.s03.e09",
    "#{und_show}.s03_e09",
    "#{show} - [03.09]",
    "#{show} - S3 E 09",
    "#{show} - Episode 9999 [S 3 - Ep 9]",
    "#{show} - Episode 9999 [S 3 - Ep 9] - ",
    "#{dot_show}.309",
    "#{dot_show}.0309",
  ].each do |filename|
    it "parse correctly the file name #{filename}" do
      Suby::FilenameParser.parse(filename+ext).should == [show, season, episode]
    end
  end
end
