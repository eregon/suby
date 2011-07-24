require_relative 'suby/downloader'

module Suby
  extend self

  SUB_EXTENSIONS = %w[srt sub]
  TEMP_ARCHIVE_NAME = '__archive__'

  def download_subtitles(files, options = {})
    files.each { |file|
      next if SUB_EXTENSIONS.include? File.extname(file)
      next puts "Skipping: #{file}" if SUB_EXTENSIONS.any? { |ext|
        File.exist? File.basename(file, File.extname(file)) + ".#{ext}" }

      begin
        found = false
        Downloader::DOWNLOADERS.each do |downloader|
          begin
            downloader.new(file, options[:lang]).download
          rescue # FIXME: rescue only expected errors
            puts "#{downloader} did not find subtitles for #{file}"
          else
            puts "#{downloader} found subtitles for #{file}"
            found = true
            break
          end
        end
        raise "Not found" unless found
      rescue
        puts "  The download of the subtitles failed for #{file}:"
        puts "  #{$!.class}: #{$!.message}"
        puts $!.backtrace.map { |line| line.prepend ' '*4 }
      end
    }
  end

  def extract_sub_from_archive(archive, format)
    case format
    when :zip
      sub = `unzip -qql #{archive}`.scan(/\d{2}:\d{2}   (.+?(?:#{SUB_EXTENSIONS.join '|'}))$/).map(&:first).first
      raise "no subtitles in #{archive}" unless sub
      sub_for_unzip = sub.gsub(/(\[|\])/) { "\\#{$1}" }
      system 'unzip', archive, sub_for_unzip, 1 => :close
      puts "found subtitle: #{sub}" if $VERBOSE
    else
      raise "unknown archive type (#{archive})"
    end

    # Cleaning
    File.unlink archive
    sub
  end
end
