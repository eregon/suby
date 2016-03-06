require_relative 'spec_helper'
require 'tmpdir'
require 'digest/md5'

describe Suby do
  file = 'How I Met Your Mother 3x9 - Slapsgiving.mkv'
  srt  = 'How I Met Your Mother 3x9 - Slapsgiving.srt'

  it 'works :D', full: true do
    Dir.mktmpdir do |dir|
      suby = File.expand_path('../../bin/suby', __FILE__)
      Dir.chdir(dir) do
        system suby, file
        subs = File.read(srt)
        subs.should match(/slapsgiving/i)
      end
    end
  end

  it 'can detect videos' do
    %w[avi mp4 mkv].each { |ext|
      Suby.should be_a_video(Path("file").add_ext(ext))
    }
    %w[txt srt sub].each { |ext|
      Suby.should_not be_a_video(Path("file").add_ext(ext))
    }
  end
end
