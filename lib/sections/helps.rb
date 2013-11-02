require_relative 'section'
require_relative '../helpers/tilde'
require_relative '../helpers/has_quoted_keywords'

# Helps section and HelpEntry classes contained within this file

# Helps section follows this pattern:
#
# #HELPS
# \d+ keyword 'multiple keywords'~
# Text for 0 or more lines
# ~
# 0$~
#
# The delimiter 0$~ sometimes has a space between the 0 and the $
# The tilde closing off a help file text can be on the same line as the
# text, but will throw a warning (it's ugly). There can be many blocks
# of help files between #HELPS and 0$~ as long as they have both a
# header with a level and a body.

class Helps < Section

  @ERROR_MESSAGES = {
    no_delimiter: "#HELPS section lacks terminating 0$~",
    continues_after_delimiter: "#HELPS section continues after terminating 0$~"
  }

  attr_reader :help_files

  @section_delimiter = "0 ?\\$~"

  def initialize(contents, line_number=1)
    super(contents, line_number)
    @id = "HELPS"

    @help_files = []
    slice_first_line # Takes off section name header
  end

  def split_help_files

    # grabs the delimiter and whatever (erroneous) content is after it
    @delimiter = slice_delimiter

    expect_header = true
    help_body = ""
    line_number = @current_line

    @contents.each_line do |line|
      @current_line += 1
      help_body << line.dup

      if expect_header
        line_number = @current_line
        expect_header = false
      elsif line.include? "~"
        expect_header = true
        self.help_files << HelpFile.new(help_body, line_number)
        help_body = ""
      end
    end
    # One more Help file just in case it lacked a tilde and wasn't pushed on before
    self.help_files << HelpFile.new(help_body, line_number) unless help_body.empty?

  end

  def parse
    split_help_files

    @help_files.each do |help_file|
      # help_file.parse
      @errors += help_file.errors
    end

    @current_line += 1
    if @delimiter.nil?
      err(@current_line, nil, Helps.err_msg(:no_delimiter))
    else
      unless @delimiter.rstrip =~ /#{Helps.delimiter(:start)}\z/
        line_num, bad_line = invalid_text_after_delimiter(@current_line, @delimiter)
        err(line_num, bad_line, Helps.err_msg(:continues_after_delimiter))
      end
    end

  end

end

class HelpFile
  include Parsable
  include TheTroubleWithTildes
  include HasQuotedKeywords

  attr_reader :level, :keywords, :body, :line_number

  def initialize(contents, line_number=1)
    @line_number = line_number
    @current_line = line_number
    @contents = contents.rstrip
    @errors = []
  end

  def parse

    first_line = @contents.slice!(/\A.*(?:\n|\Z)/).strip

    # N.B. Help file level can be negative
    first_line.match(/\A(-?\d+)\s+/) do |m|
      @level = m[1].to_i

      keywords = m.post_match
      unless has_tilde?(keywords)
        err(@current_line, first_line, tilde(:absent))
      else
        err(@current_line, first_line, tilde(:extra_text)) unless trailing_tilde?(keywords)
      end
      nab_tilde(keywords)

      # see HasQuotedKeywords module for details
      @keywords = parse_quoted_keywords(keywords, first_line)

    end # if first line starts with a number
    if self.level.nil?
      err(@current_line, first_line, "Help file doesn't start with a level")
    end

    # First line done with. Onto the body.
    @current_line += @contents.count("\n") + 1
    end_line = @contents[/^.*~.*$/]
    if !has_tilde?(@contents)
      err(@current_line, nil, tilde(:absent, "Help file body"))
    elsif !trailing_tilde?(end_line)
      err(@current_line, end_line, tilde(:extra_text, "Help file body"))
    elsif !isolated_tilde?(end_line)
      ugly(@current_line, end_line, tilde(:not_alone))
    end

  end

end