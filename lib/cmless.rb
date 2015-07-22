# require_relative 'cmless/cmless'
# If this becomes multiple files, then require a subdirectory.
# but if it's just one file, it's fine here.

require 'redcarpet'
require 'singleton'
require 'nokogiri'

class Cmless

  module Markdowner
    include Singleton
  
    @markdown = Redcarpet::Markdown.new(
                  Redcarpet::Render::XHTML.new(with_toc_data: true), 
                  autolink: true)
  
    def render(md_text)
      return unless md_text
      @markdown.render(md_text)
    end
  end

  def self.objects_by_path
    @objects_by_path ||= 
      Hash[
        Dir[self.root_path + '**/*.md'].sort.map do |path|
          object = self.new(path)
          [object.path, object]
        end
      ]
  end
  
  def self.find_by_path(path)
    self.objects_by_path[path] || raise(IndexError.new("'#{path}' is not a valid path under '${self.root_path}'"))
  end

  def ancestors
    @ancestors ||= begin
      split = path.split('/')
      (1..split.size-1).to_a.map do |i|
        self.class.exhibits_by_path[split[0,i].join('/')]
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
    file_path.to_s.gsub(self.exhibit_root.to_s+'/', '').gsub(/\.md$/, '')
  end

  def initialize(file_path)
    @path = self.class.path_from_file_path(file_path)
    Nokogiri::HTML(Markdowner.render(File.read(file_path))).tap do |doc|
      @name = doc.xpath('//h1').first.remove.text

# TODO: iterate over defined accessors.      
#      @summary_html = Exhibit::extract_html(doc, 'Summary')
#      @author_html = Exhibit::extract_html(doc, 'Author')
      
      doc.text.strip.tap do |extra|
        fail("#{file_path} has extra unused text: '#{extra}'") unless extra == ''
      end
    end
  end
  
end
