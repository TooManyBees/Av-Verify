require_relative "section"

class VnumSection < Section

  @ERROR_MESSAGES = {
    invalid_vnum: "Invalid %s VNUM",
    invalid_after_vnum: "Invalid text on same line as VNUM",
    duplicate: "Duplicate %s #%i, first appears on line %i",
    empty: "%s section is empty!"
  }

  def initialize(options)
    super(options)
    @children = []
  end

  def child_regex
    /^(?=#\d\S*)/
  end

  # A proc to pass to Section#split_children to determine whether or not to add
  # the the child to the instance var @children. Also raises errors
  def child_validator
    Proc.new do |child|
      child_vnum = child[/\A#\d+\b/]
      invalid = false

      unless child_vnum
        # invalid vnums won't be added (sorry!)
        err(@current_line, child[/\A.*$/], VnumSection.err_msg(:invalid_vnum, self.id.upcase))
        invalid == true
      end
      unless child =~ /\A#\w+\s*$/
        err(@current_line, child[/\A.*$/], VnumSection.err_msg(:invalid_after_vnum))
      end

      !invalid
    end
  end

  def [](vnum)
    self.children.find { |child| child.vnum == vnum }
  end

  def include?(vnum)
    self.children.any? { |child| child.vnum == vnum }
  end

  def length
    self.children.length
  end

  def size
    length
  end

  def each(&prc)
    self.children.each(&prc)
  end

  def split_children
    super
  end

  def parse
    @parsed = true

    split_children

    if self.children.empty?
      err(self.line_number, nil, VnumSection.err_msg(:empty, self.class.name))
      @parsed = true
    end

    self.children.each do |entry|
      entry.parse

      existing_entry = self[entry.vnum]
      unless existing_entry.equal?(entry)
        err(
          entry.line_number, nil,
          VnumSection.err_msg(
            :duplicate, entry.class.name.downcase, entry.vnum, existing_entry.line_number
          )
        )
      end

      self.errors += entry.errors
    end

    verify_delimiter
    self.children
  end

end
