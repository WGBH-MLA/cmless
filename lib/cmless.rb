# require_relative 'cmless/cmless'
# If this becomes multiple files, then require a subdirectory.
# but if it's just one file, it's fine here.

require 'redcarpet'
require 'singleton'
require 'nokogiri'

# CMS alternative: Content in markdown / Extract HTML and data for display
class Cmless
  attr_reader :path
  attr_reader :title

  private

  # You should use find_by_path rather than creating your own instances.
  def initialize(file_path) # rubocop:disable Metrics/MethodLength
    @path = self.class.path_from_file_path(file_path)
    Nokogiri::HTML(Markdowner.instance.render(File.read(file_path))).tap do |doc|
      @title = doc.xpath('//h1').first.remove.text

      html_methods = self.class.instance_methods
                     .select { |method| method.to_s.match(/\_html$/) }

      if html_methods.include?(:head_html)
        instance_variable_set('@head_html', Cmless.extract_head_html(doc))
        html_methods.delete(:head_html)
      end

      if html_methods.include?(:body_html)
        instance_variable_set('@body_html', Cmless.extract_body_html(doc))
        html_methods.delete(:body_html)
      end

      html_methods.each do |method|
        h2_name = method.to_s.gsub(/\_html$/, '').gsub('_', ' ').capitalize
        instance_variable_set("@#{method}", Cmless.extract_html(doc, h2_name))
      end

      doc.text.strip.tap do |extra|
        escaped = extra.gsub("\n", '\\n').gsub("\t", '\\t')
        fail("#{file_path} has extra unused text: '#{escaped}'") unless extra == ''
      end
    end
  end

  public

  # Instance methods:

  def ancestors
    @ancestors ||= begin
      split = path.split('/')
      (1..split.size - 1).to_a.map do |i|
        self.class.objects_by_path[split[0, i].join('/')]
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

  # Class methods:

  def self.all
    objects_by_path.values
  end

  def self.objects_by_path
    @objects_by_path ||=
      begin
        unless File.directory?(self::ROOT)
          fail StandardError.new("#{self::ROOT} is not a directory")
        end
        Hash[
          Dir[Pathname(self::ROOT) + '**/*.md'].sort.map do |path|
            object = new(path)
            [object.path, object]
          end
        ]
      end
  end

  def self.find_by_path(path)
    objects_by_path[path] || fail(IndexError.new("'#{path}' is not a valid path under '#{self::ROOT}'; Expected one of #{objects_by_path.keys}"))
  end

  def self.path_from_file_path(file_path)
    file_path.to_s.gsub(self::ROOT + '/', '').gsub(/\.md$/, '')
  end

  def self.extract_html(doc, title)
    following_siblings = []
    doc.xpath("//h2[text()='#{title}']").first.tap do |header|
      fail IndexError.new("Can't find header '#{title}'") unless header
      while header.next_element && !header.next_element.name.match(/h2/)
        following_siblings.push(header.next_element.remove)
      end
      header.remove
    end
    following_siblings.map(&:to_s).join
  end

  def self.extract_head_html(doc)
    siblings = []
    body = doc.xpath('//body').first
    while body.children.first && !body.children.first.name.match(/h2/)
      siblings.push(body.children.first.remove)
    end
    siblings.map(&:to_s).join.strip
  end

  def self.extract_body_html(doc)
    siblings = []
    body = doc.xpath('//body').first
    while body.children.first
      siblings.push(body.children.first.remove)
    end
    siblings.map(&:to_s).join.strip
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
