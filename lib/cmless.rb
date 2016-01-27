# require_relative 'cmless/cmless'
# If this becomes multiple files, then require a subdirectory.
# but if it's just one file, it's fine here.

require 'redcarpet'
require 'singleton'
require 'nokogiri'
require 'cgi'

# CMS alternative: Content in markdown / Extract HTML and data for display
class Cmless
  attr_reader :path
  attr_reader :title
  attr_reader :title_html
  attr_reader :toc_html

  private

  # You should use find_by_path rather than creating your own instances.
  def initialize(file_path)
    @path = self.class.path_from_file_path(file_path)
    Nokogiri::HTML(Markdowner.instance.render(File.read(file_path))).tap do |doc|
      html_methods = self.class.instance_methods
                     .select { |method| method.to_s.match(/\_html$/) } - [:toc_html]

      doc.xpath('//h1').first.tap do |h1|
        @title_html = h1.inner_html
        @title = h1.text
        h1.remove
        html_methods.delete(:title_html)
      end

      doc.xpath('//h3|//h4|//h5|//h6|//h7|//h8|//h9').tap do |hs|
        inner = hs.map do |h|
          escaped = CGI.escapeHTML(h.text)
          hash = '#' + CGI.escapeHTML(h.attribute('id').to_s)
          "<li class='cmless cmless-#{h.name}'><a href='#{hash}'>#{escaped}</a></li>"
        end.join("\n")
        @toc_html = inner.empty? ? '' : "<ol class='cmless'>#{inner}</ol>\n"
      end

      if html_methods.include?(:head_html)
        @head_html = Cmless.extract_head_html(doc)
        html_methods.delete(:head_html)
      end

      if html_methods.include?(:body_html)
        @body_html = Cmless.extract_body_html(doc)
        html_methods.delete(:body_html)
      end

      html_methods.each do |method|
        h2_name = method.to_s.gsub(/\_html$/, '').gsub('_', ' ').capitalize
        value = Cmless.extract_html(doc, h2_name)
        value ||= if parent # Look at parent if missing on self.
                    parent.send(method)
                  else
                    fail(IndexError.new("Can't find '#{method}'"))
                  end
        instance_variable_set("@#{method}", value)
      end

      doc.text.strip.tap do |extra|
        escaped = extra.gsub("\n", '\\n').gsub("\t", '\\t')
        fail("#{file_path} has extra unused text: '#{escaped}'") unless extra == ''
      end
    end
  rescue => e
    raise(e.message + ' in ' + file_path)
  end

  public

  # Instance methods:

  def parent
    ancestors.last
  end

  def ancestors
    @ancestors ||= begin
      split = path.split('/')
      (1..split.size - 1).to_a.map do |i|
        # to avoid infinite recursion, only look at the ones already loaded.
        self.class.objects_by_path_in_progress[split[0, i].join('/')]
      end
    end
  end

  def children
    @children ||= begin
      self.class.objects_by_path.select do |other_path, _other_object|
        other_path.match(/^#{path}\/[^\/]+$/) # TODO: escape
      end.map do |_other_path, other_object|
        other_object
      end
    end
  end

  class << self
    include Enumerable

    def each(&block)
      all.each do |cmless|
        block.call(cmless)
      end
    end

    def all
      @all ||= objects_by_path.values.sort_by do |object|
        object.head_html.gsub('<p>', '').to_f rescue object.path
      end
    end

    def find_by_path(path)
      objects_by_path[path] ||
        fail(IndexError.new(
               "'#{path}' is not a valid path under '#{self::ROOT}'; " \
                 "Expected one of #{objects_by_path.keys}"))
    end

    def objects_by_path_in_progress
      @object_by_path_in_progress
    end

    def objects_by_path
      @objects_by_path ||=
        begin
          unless File.directory?(self::ROOT)
            fail StandardError.new("#{self::ROOT} is not a directory")
          end
          @object_by_path_in_progress = {}
          Dir[Pathname(self::ROOT) + '**/*.md'].sort.each do |full_path|
            object = new(full_path)
            @object_by_path_in_progress[object.path] = object
          end
          @object_by_path_in_progress
        end
    end

    # These are just used by the initialize. Perhaps there is a better place.

    def path_from_file_path(file_path)
      file_path.to_s.gsub(self::ROOT + '/', '').gsub(/\.md$/, '')
    end

    def extract_html(doc, title)
      following_siblings = []
      # UGLY:
      # - title coming in is based on method name,
      #   so it will only be [a-z0-9_].
      # - Nokogiri only has XPath 1.0, so no regex replacements,
      #   so we can't list every possible bad character.
      # - XPath itself does not have a syntax for escaping in string literals,
      #   so we concat.
      doc.xpath("//h2[translate(text(),concat('~!@#\{$%^&*()_+`-=\}-\";:<>,.?/|\[]',\"'\"),'')='#{title}']").first.tap do |header|
        return nil unless header
        while header.next_element && !header.next_element.name.match(/h2/)
          following_siblings.push(header.next_element.remove)
        end
        header.remove
      end
      following_siblings.map(&:to_s).join
    end

    def extract_head_html(doc)
      siblings = []
      body = doc.xpath('//body').first
      while body.children.first && !body.children.first.name.match(/h2/)
        siblings.push(body.children.first.remove)
      end
      siblings.map(&:to_s).join.strip
    end

    def extract_body_html(doc)
      siblings = []
      body = doc.xpath('//body').first
      siblings.push(body.children.first.remove) while body.children.first
      siblings.map(&:to_s).join.strip
    end
  end

  # Utility class: (This could move.)
  # Just a wrapper for Redcarpet
  class Markdowner
    include Singleton

    def initialize
      @markdown = Redcarpet::Markdown.new(
        Redcarpet::Render::XHTML.new(with_toc_data: true),
        autolink: true)
    end

    def render(md_text)
      return unless md_text
      @markdown.render(md_text)
    end
  end
end
