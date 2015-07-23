require_relative '../lib/cmless.rb'

describe Cmless do
  
  describe 'correctly configured' do
    
    describe 'basic' do
      
      class Basic < Cmless
        def self.root_path
          File.expand_path('fixtures/good/basic', File.dirname(__FILE__))
        end
        attr_reader :summary_html
        attr_reader :can_be_multi_word_html
      end
      
      basic = Basic.find_by_path('basic')

      assertions = {
        title: 'Basic!',
        path: 'basic',
        ancestors: [],
        children: [],
        can_be_multi_word_html: '<p>Should work, too.</p>',
        summary_html: '<p>Summary goes here.</p>'
      }

      assertions.each do |method, value|
        it "\##{method} method works" do
          expect(basic.send(method)).to eq((value.strip rescue value))
        end
      end

      it 'tests everthing' do
        expect(assertions.keys.sort).to eq((Basic.instance_methods - Object.instance_methods).sort)
      end
      
      it 'raises an error for bad paths' do
        expect {Basic.find_by_path('no/such/path')}.to raise_error(IndexError)
      end
      
    end
    
    describe 'hierarchical' do
  
      class Hierarchy < Cmless
        def self.root_path
          File.expand_path('fixtures/good/hierarchy', File.dirname(__FILE__))
        end
      end

      grandchild = Hierarchy.find_by_path('parent/child/grandchild')

      assertions = {
        title: 'Grandchild!',
        path: 'parent/child/grandchild',
        ancestors: [
          Hierarchy.find_by_path('parent'),
          Hierarchy.find_by_path('parent/child')],
        children: [
          Hierarchy.find_by_path('parent/child/grandchild/greatgrandchild1'), 
          Hierarchy.find_by_path('parent/child/grandchild/greatgrandchild2')]
      }

      assertions.each do |method, value|
        it "\##{method} method works" do
          expect(grandchild.send(method)).to eq((value.strip rescue value))
        end
      end

      it 'tests everthing' do
        expect(assertions.keys.sort).to eq((Hierarchy.instance_methods - Object.instance_methods).sort)
      end
      
    end
    
  end

  describe 'mis-configured' do
    
    describe 'misspelled h2' do
      class WrongName < Cmless
        def self.root_path
          File.expand_path('fixtures/bad/wrong-name', File.dirname(__FILE__))
        end

        attr_reader :summary_html
        attr_reader :author_html
      end
      
      it 'errors' do
        expect { WrongName.find_by_path('wrong-name')}.to raise_error(/Can't find header/)
      end
    end
    
    describe 'extra cruft' do
      class ExtraCruft < Cmless
        def self.root_path
          File.expand_path('fixtures/bad/extra-cruft', File.dirname(__FILE__))
        end
      end
      
      it 'errors' do
        expect { ExtraCruft.find_by_path('extra-cruft')}.to raise_error(/Extra Cruft\\n\\nShould cause an error/)
      end
    end
    
    describe 'missing #root_path' do
      class MissingRootPath < Cmless
        # What happens if we forget "def self.root_path"?
      end
      
      it 'errors' do
        expect { MissingRootPath.find_by_path('does-not-matter')}.to raise_error(/undefined method `root_path'/)
      end
    end
    
  end

end