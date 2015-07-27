require_relative '../lib/cmless.rb'

describe Cmless do
  describe 'correctly configured' do
    describe 'basic' do
      class Basic < Cmless
        ROOT = File.expand_path('fixtures/good/basic', File.dirname(__FILE__))
        attr_reader :head_html
        attr_reader :summary_html
        attr_reader :can_be_multi_word_html
      end

      basic = Basic.find_by_path('basic')

      assertions = {
        title_html: '<a href="http://example.org/work">links in title</a> <strong>&amp; style!</strong>',
        path: 'basic',
        ancestors: [],
        children: [],
        head_html: '<p>Head goes here.</p>',
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
        expect { Basic.find_by_path('no/such/path') }.to raise_error(IndexError)
      end
      
      describe 'error on modification' do
        it 'does not have setters' do
          expect { Basic.find_by_path('basic').title_html = 'new title' }
            .to raise_error(NoMethodError)
        end
        xit 'errors on direct attribute access' do
          # Freezing the objects after creation doesn't work right now
          # because @ancestors and @children are only filled in lazily.
          expect { Basic.find_by_path('basic').instance_variable_set(:@title_html, 'new title') }
            .to raise_error
        end
      end
    end

    describe 'body' do
      class Body < Cmless
        ROOT = File.expand_path('fixtures/good/body', File.dirname(__FILE__))
        attr_reader :body_html
      end

      body = Body.find_by_path('body')

      assertions = {
        title_html: 'Just a title',
        path: 'body',
        ancestors: [],
        children: [],
        body_html: "<p>and a body</p>\n\n<h2 id=\"which\">which</h2>\n\n<p>includes everything.</p>"
      }

      assertions.each do |method, value|
        it "\##{method} method works" do
          expect(body.send(method)).to eq((value.strip rescue value))
        end
      end

      it 'tests everthing' do
        expect(assertions.keys.sort).to eq((Body.instance_methods - Object.instance_methods).sort)
      end
    end

    class Hierarchy < Cmless
      ROOT = File.expand_path('fixtures/good/hierarchy', File.dirname(__FILE__))
    end
    
    describe 'hierarchical' do
      grandchild = Hierarchy.find_by_path('parent/child/grandchild')

      assertions = {
        title_html: 'Grandchild!',
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
    
    describe 'class methods' do
      
      paths = [
        'parent', 'parent/child', 'parent/child/grandchild',
        'parent/child/grandchild/greatgrandchild1',
        'parent/child/grandchild/greatgrandchild2']
      title_htmls = [
        'Parent!', 'Child!', 'Grandchild!', 
        'Greatgrandchild1!', 'Greatgrandchild2!']
      
      it '#all works' do
        expect(Hierarchy.all.map(&:path).sort).to eq(paths)
      end
      
      it '#objects_by_path works' do
        expect(Hierarchy.objects_by_path.keys.sort).to eq(paths)
      end
      
      it '#find_by_path works' do
        expect(Hierarchy.find_by_path('parent').path).to eq('parent')
      end
      
      describe 'Enumerable' do
        it 'supports #map' do
          expect(Hierarchy.map(&:path)).to eq(paths)
          expect(Hierarchy.map(&:title_html)).to eq(title_htmls)
        end
      end
    end
  end

  describe 'mis-configured' do
    describe 'misspelled h2' do
      class WrongName < Cmless
        ROOT = File.expand_path('fixtures/bad/wrong-name', File.dirname(__FILE__))
        attr_reader :summary_html
        attr_reader :author_html
      end

      it 'errors' do
        expect { WrongName.find_by_path('wrong-name') }.to raise_error(/Can't find header/)
      end
    end

    describe 'extra cruft' do
      class ExtraCruft < Cmless
        ROOT = File.expand_path('fixtures/bad/extra-cruft', File.dirname(__FILE__))
      end

      it 'errors' do
        expect { ExtraCruft.find_by_path('extra-cruft') }.to raise_error(/Extra Cruft\\n\\nShould cause an error/)
      end
    end

    describe 'missing #root_path' do
      class MissingRootPath < Cmless
        # What happens if we forget ROOT?
      end

      it 'errors' do
        expect { MissingRootPath.find_by_path('does-not-matter') }.to raise_error(/uninitialized constant MissingRootPath::ROOT/)
      end
    end

    describe 'bad #root_path' do
      class BadRootPath < Cmless
        ROOT = '/no/such/path'
      end

      it 'errors' do
        expect { BadRootPath.find_by_path('does-not-matter') }.to raise_error(/is not a directory/)
      end
    end
  end
end
