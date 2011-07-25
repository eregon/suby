module Suby
  module FilenameParser
    extend self

    def parse file
      unless /^(?<show>.+) (?<season>\d{1,2})x(?<episode>\d{1,2})(?: - (?<title>.+))?\.[a-z]+?$/ =~ file
        raise "wrong file format (#{file}). Must be:\n<show> <season>x<episode>[ - <title>].<ext>"
      end
      [show, season.to_i, episode.to_i, title]
    end
  end
end
