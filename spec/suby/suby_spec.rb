require_relative '../spec_helper'
require 'tmpdir'
require 'digest/md5'

describe Suby do
  file = 'How I Met Your Mother 3x9 - Slapsgiving.mkv'
  srt  = 'How I Met Your Mother 3x9 - Slapsgiving.srt'

  it 'works :D' do
    Dir.mktmpdir do |dir|
      suby = File.expand_path('../../../bin/suby', __FILE__)
      Dir.chdir(dir) do
        system suby, file
        Digest::MD5.hexdigest(File.read(srt)).should == '66c4d3b40839a957f218e043105a1352'
      end
    end
  end
end
