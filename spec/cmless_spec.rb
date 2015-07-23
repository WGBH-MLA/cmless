require_relative '../lib/cmless.rb'

describe Cmless do
  
  describe 'correctly configured' do
  
    class TestCmless < Cmless
      def self.root_path
        File.expand_path('fixtures/good', File.dirname(__FILE__))
      end
      
      attr_reader :summary_html
      attr_reader :author_html
    end

    exhibit = TestCmless.find_by_path('parent/child/grandchild')

    assertions = {
      title: 'Grandchild!',
      path: 'parent/child/grandchild',
      ancestors: [
        TestCmless.find_by_path('parent'),
        TestCmless.find_by_path('parent/child')],
      children: [
        TestCmless.find_by_path('parent/child/grandchild/greatgrandchild1'), 
        TestCmless.find_by_path('parent/child/grandchild/greatgrandchild2')],
      author_html: '<p>Author goes here.</p>',
      summary_html: '<p>Summary goes here.</p>'
    }

    assertions.each do |method, value|
      it "\##{method} method works" do
        expect(exhibit.send(method)).to eq((value.strip rescue value))
      end
    end

    it 'tests everthing' do
      expect(assertions.keys.sort).to eq((TestCmless.instance_methods - Object.instance_methods).sort)
    end

    describe 'error handling' do
      it 'raises an error for bad paths' do
        expect {TestCmless.find_by_path('no/such/path')}.to raise_error(IndexError)
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
  end

end