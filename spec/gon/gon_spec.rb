# gon_spec_rb
require 'gon'

describe Gon, '#all_variables' do

  before(:each) do
    Gon.request_env = {}
  end

  it 'returns all variables in hash' do
    Gon.a = 1
    Gon.b = 2
    Gon.c = Gon.a + Gon.b
    Gon.c.should == 3
    Gon.all_variables.should == {'a' => 1, 'b' => 2, 'c' => 3}
  end

  it 'supports all data types' do
    Gon.clear
    Gon.int = 1
    Gon.float = 1.1
    Gon.string = 'string'
    Gon.array = [ 1, 'string' ]
    Gon.hash_var = { :a => 1, :b => '2'}
    Gon.hash_w_array = { :a => [ 2, 3 ] }
    Gon.klass = Hash
  end

  it 'output as js correct' do
    Gon.clear
    Gon.int = 1
    ActionView::Base.instance_methods.map(&:to_s).include?('include_gon').should == true
    base = ActionView::Base.new
    base.include_gon.should == "<script>window.gon = {};" +
                                 "gon.int=1;" +
                               "</script>"
  end

  it 'returns exception if try to set public method as variable' do
    Gon.clear
    lambda { Gon.all_variables = 123 }.should raise_error
  end

  describe '.rabl' do
    require 'rabl'
    require 'gon/rabl'

    before :each do
      Gon.clear
      controller.instance_variable_set('@objects', objects)
    end

    let(:controller) { ActionController::Base.new}
    let(:objects) { [1,2]}

    context 'render template with deprecation' do
      it 'still works' do
        Gon.rabl 'spec/test_data/sample.rabl', :controller => controller
        Gon.objects.length.should == 2
      end
    end

    it 'works if rabl is included' do
      Gon.rabl :template =>'spec/test_data/sample.rabl', :controller => controller
      Gon.objects.length.should == 2
    end

    it 'raise exception if rabl is not included' do
      Gon.send :remove_const, 'Rabl'
      expect { Gon.rabl :template =>'spec/test_data/sample.rabl', :controller => controller}.to raise_error
      load 'rabl.rb'
      load 'gon/rabl.rb'
    end

  end

  describe '.get_template_path' do

    context 'template is specified' do
      it 'add the extension if not included in the template name' do
        Gon.send(:get_template_path, { :template => 'spec/test_data/sample'}, 'rabl').should eql('spec/test_data/sample.rabl')
      end

      it 'return the specified template' do
        Gon.send(:get_template_path, { :template => 'spec/test_data/sample.rabl'}, 'rabl').should eql('spec/test_data/sample.rabl')
      end
    end

    context 'template is not specified' do
      before do
        Gon.clear
        controller.instance_variable_set('@objects', objects)
        controller.action_name = 'show'
      end

      let(:controller) { ActionController::Base.new}
      let(:objects) { [1,2]}

      context 'the action doesn as a template at a different format' do
        it 'return the same template as the action with rabl extension' do
          Gon.send(:get_template_path, {:controller => controller}, 'rabl').should eql('app/views/action_controller/base/show.json.rabl')
        end
      end
      context 'the action as a template at a different format' do
        it 'return the same template as the action with rabl extension' do
          Gon.send(:get_template_path, {:controller => controller}, 'rabl').should eql('app/views/action_controller/base/show.json.rabl')
        end
      end
    end
  end

  if RUBY_VERSION =~ /1.9/
    require 'jbuilder'
    require 'gon/jbuilder'

    it 'render json from jbuilder template' do
      Gon.clear
      controller = ActionController::Base.new
      objects = [1,2]
      controller.instance_variable_set('@objects', objects)
      Gon.jbuilder 'spec/test_data/sample.json.jbuilder', :controller => controller
      Gon.objects.length.should == 2
    end

    it 'render json from jbuilder template with a partial' do
      Gon.clear
      controller = ActionController::Base.new
      controller.view_paths << 'spec/test_data'
      objects = [1,2]
      controller.instance_variable_set('@objects', objects)
      Gon.jbuilder 'spec/test_data/sample_with_partial.json.jbuilder', :controller => controller
      Gon.objects.length.should == 2
    end

    it 'should throw error if you use gon.jbuilder with ruby < 1.9+' do
      RUBY_VERSION = '1.8.7'

      expect { Gon.jbuilder 'some_path'}.to raise_error(NoMethodError, /1.9/)
    end

    it 'should raise error if you use gon.jbuilder without requiring jbuilder gem' do
      RUBY_VERSION = '1.9.2'
      Gon.send(:remove_const, :Jbuilder)

      expect { Gon.jbuilder 'some_path' }.to raise_error(NoMethodError, /Gemfile/)
    end
  end

  def request
    @request ||= double 'request', :env => {}
  end

end
