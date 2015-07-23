# require_relative 'cmless/cmless'
# If this becomes multiple files, then require a subdirectory.
# but if it's just one file, it's fine here.

require 'redcarpet'
require 'singleton'
require 'nokogiri'

class Cmless
  
  attr_reader :path
  attr_reader :title
  
  def initialize(file_path)
    @path = self.class.path_from_file_path(file_path)
    Nokogiri::HTML(Markdowner.instance.render(File.read(file_path))).tap do |doc|
      @title = doc.xpath('//h1').first.remove.text

      # TODO: get header content.
      
      self.class.instance_methods.
        select { |method| method.to_s.match(/\_html$/) }.
        each do |method|
          h2_name = method.to_s.gsub(/\_html$/, '').gsub('_',' ').capitalize
          variable_name = "@#{method.to_s}"
          self.instance_variable_set(variable_name, Cmless.extract_html(doc, h2_name))
        end
      
      doc.text.strip.tap do |extra|
        escaped = extra.gsub("\n",'\\n').gsub("\t",'\\t')
        fail("#{file_path} has extra unused text: '#{escaped}'") unless extra == ''
      end
    end
  end
  
  
  # Instance methods:
  
  def ancestors
    @ancestors ||= begin
      split = path.split('/')
      (1..split.size-1).to_a.map do |i|
        self.class.objects_by_path[split[0,i].join('/')]
      end
    end
  end
  
  def children
    @children ||= begin
      self.class.objects_by_path.select do |other_path, other_object|
        other_path.match(/^#{path}\/[^\/]+$/) # TODO: escape
      end.map do |other_path, other_object|
        other_object
      end
    end
  end
  
  
  # Class methods:
  
  def self.objects_by_path
    @objects_by_path ||= 
      Hash[
        Dir[Pathname(self.root_path) + '**/*.md'].sort.map do |path|
          object = self.new(path)
          [object.path, object]
        end
      ]
  end
  
  def self.find_by_path(path)
    self.objects_by_path[path] || raise(IndexError.new("'#{path}' is not a valid path under '#{self.root_path}'; Expected one of #{self.objects_by_path.keys}"))
  end

  def self.extract_html(doc, title)
    following_siblings = []
    doc.xpath("//h2[text()='#{title}']").first.tap do |header|
      raise IndexError.new("Can't find header '#{title}'") unless header
      while header.next_element && !header.next_element.name.match(/h2/) do
        following_siblings.push(header.next_element.remove)
      end
      header.remove
    end
    following_siblings.map { |el| el.to_s }.join
  end
  
  def self.path_from_file_path(file_path)
    file_path.to_s.gsub(self.root_path.to_s+'/', '').gsub(/\.md$/, '')
  end
  
  
  # Utility class: (This could move.)
  
  class Markdowner
    include Singleton
  
    def initialize()
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
