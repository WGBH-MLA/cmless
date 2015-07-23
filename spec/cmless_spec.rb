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
      name: 'Grandchild!',
      path: 'parent/child/grandchild',
      ancestors: [
        TestCmless.find_by_path('parent'),
        TestCmless.find_by_path('parent/child')],
      children: [
        TestCmless.find_by_path('parent/child/grandchild/greatgrandchild1'), 
        TestCmless.find_by_path('parent/child/grandchild/greatgrandchild2')],
    }

    assertions.each do |method, value|
      it "\##{method} method works" do
        expect(exhibit.send(method)).to eq((value.strip rescue value))
      end
    end

    it 'tests everthing' do
      expect(assertions.keys.sort).to eq(Exhibit.instance_methods(false).sort)
    end

    describe 'error handling' do
      it 'raises an error for bad paths' do
        expect {MockExhibit.find_by_path('no/such/path')}.to raise_error(IndexError)
      end
    end
  end

#  describe 'mis-configured' do
#    describe 'misspelled h2' do
#      class MisspelledH2MockExhibit < Exhibit
#        def self.exhibit_root
#          Rails.root + 'spec/fixtures/exhibits-broken/misspelled-h2'
#        end
#      end
#      
#      it 'errors' do
#        expect { MisspelledH2MockExhibit.find_by_path('misspelled-h2')}.to raise_error(/Can't find header/)
#      end
#    end
#    
#    describe 'extra cruft' do
#      class ExtraCruftMockExhibit < Exhibit
#        def self.exhibit_root
#          Rails.root + 'spec/fixtures/exhibits-broken/extra-cruft'
#        end
#      end
#      
#      it 'errors' do
#        expect { ExtraCruftMockExhibit.find_by_path('extra-cruft')}.to raise_error(/Extra Cruft\s+Should cause an error/)
#      end
#    end
#  end
end