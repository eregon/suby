module Suby
  module FilenameParser
    extend self

    # from tvnamer @ ab2c6c, with author's agreement, adapted
    # See https://github.com/dbr/tvnamer/blob/master/tvnamer/config_defaults.py
    TVSHOW_PATTERNS = [
      # foo.s0101
      /^(?<show>.+?)
      [ \._\-]
      [Ss](?<season>[0-9]{2})
      [\.\- ]?
      (?<episode>[0-9]{2})
      [^0-9]*$/x,

      # foo.1x09*
      /^(?<show>.+?)
      [ \._\-]
      \[?
      (?<season>[0-9]+)
      [xX]
      (?<episode>[0-9]+)
      \]?
      [^\/]*$/x,

      # foo.s01.e01, foo.s01_e01
      /^(?<show>.+?)
      [ \._\-]
      \[?
      [Ss](?<season>[0-9]+)[\. _-]?
      [Ee]?(?<episode>[0-9]+)
      \]?
      [^\/]*$/x,

      # foo - [01.09]
      /^(?<show>.+?)
      [ \._\-]?
      \[
      (?<season>[0-9]+?)
      [.]
      (?<episode>[0-9]+?)
      \]
      [ \._\-]?
      [^\/]*$/x,

      # Foo - S2 E 02 - etc
      /^(?<show>.+?)
      [ ]?[ \._\-][ ]?
      [Ss](?<season>[0-9]+)[\.\- ]?
      [Ee]?[ ]?(?<episode>[0-9]+)
      [^\/]*$/x,

      # Show - Episode 9999 [S 12 - Ep 131] - etc
      /(?<show>.+)
      [ ]-[ ]
      [Ee]pisode[ ]\d+
      [ ]
      \[
      [sS][ ]?(?<season>\d+)
      ([ ]|[ ]-[ ]|-)
      ([eE]|[eE]p)[ ]?(?<episode>\d+)
      \]
      .*$/x,

      # foo.103*
      /^(?<show>.+)
      [ \._\-]
      (?<season>[0-9]{1})
      (?<episode>[0-9]{2})
      [\._ -][^\/]*$/x,
    ]
    MOVIE_PATTERN = /^(?<movie>.*)[\[.(| ]{1}(?<year>(?:(?:19|20)[0-9]{2}))/i

    def parse(file)
      filename = file.basename.to_s
      found = TVSHOW_PATTERNS.find { |pattern|
        pattern =~ filename
      }
      if found
        { type: :tvshow, show: clean_show_name($~[:show]), season: $~[:season].to_i, episode: $~[:episode].to_i }
      elsif MOVIE_PATTERN =~ filename
        { type: :movie, name: clean_show_name($~[:movie]), year: $~[:year].to_i }
      else
        { type: :unknown, name: filename }
      end
    end

    # from https://github.com/dbr/tvnamer/blob/master/tvnamer/utils.py#L78-95
    # Cleans up series name by removing any . and _
    # characters, along with any trailing hyphens.
    #
    # Is basically equivalent to replacing all _ and . with a
    # space, but handles decimal numbers in string.
    #
    #   clean_show_name("an.example.1.0.test") # => "an example 1.0 test"
    #   clean_show_name("an_example_1.0_test") # => "an example 1.0 test"
    def clean_show_name show
      show.gsub!(/(?<!\d)[.]|[.](?!\d)/, ' ')
      show.tr!('_', ' ')
      show.chomp!('-')
      show.strip!
      show
    end
  end
end
