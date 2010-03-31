require 'spec_helper'

def define_model
  Object.send(:remove_const,:MyModel) if defined? MyModel
  Object.send(:const_set, :MyModel, Class::new(Sequel::Model(DB[:cool_sequel])))
  MyModel
end

describe BabySitter do

  before(:all) do 
    DB.create_table(:cool_sequel) do
      primary_key :id
      String  :string
      Integer :integer
    end unless DB.table_exists? :cool_sequel

  end

  after(:all) do
    DB.drop_table :cool_sequel
  end

  describe "(before cool)" do
    before(:all) { @klass = define_model }

    describe " #create" do
      it "should alias initialize as orig_initialize" do
        @klass.should_not respond_to :orig_create
        @klass.class_eval { include BabySitter }
        @klass.should respond_to :orig_create
      end
    end

    describe" #save" do
      it "should alias save as orig_save" do
        @klass.new.should respond_to :save
        @klass.new.should_not respond_to :orig_save
        @klass.class_eval { include BabySitter }
        @klass.new.should respond_to :orig_save
      end
    end
  end

  describe "(after cool)" do
    before(:all) { @klass = define_model; @klass.class_eval { include BabySitter } }

    it "should #create a model the same way" do
      model = @klass.create(:integer => 3, :string => "hello")
      model.string.should  eql("hello")
      model.integer.should eql(3)
    end

    it "should take a settings block as a paramater now on #create" do
      p = Proc.new { |m| m.string = "hello world" }
      model = @klass.create( {:integer => 3} , p)
      model.string.should eql("hello world")
      model.integer.should eql(3)
    end

    it "should take an optional block to handle errors that sequel can raise" do
      pi = Proc.new { |m| m.string = "hello world" }
      model = @klass.create( {:int => 3} , pi) do |klass,values|
        $!.class.should eql Sequel::Error
        klass.should eql(@klass)
        true
      end
      model.should be(true)
    end

    it "should allow you to retry an operation after manipulating the params" do
      pi = Proc.new { |m| m.string = "hello world" }
      model = @klass.create( {:int => 3} , pi) do |klass,values|
        $!.class.should eql Sequel::Error
        klass.should eql(@klass)
        values.delete(:int)
        :retry
      end
      model.string.should eql("hello world")
      model.should be_an_instance_of(MyModel)
    end

    it "should set the trouble maker when using #new" do
      BabySitter.TroubleHandled
      lambda { model = @klass.new(:int => 3) }.should raise_error(Sequel::Error)
      BabySitter.TroubleMaker.should eql(MyModel)
    end

    it "should set the trouble maker when an error occurs for reference" do
      BabySitter.TroubleHandled
      lambda { model = @klass.create( {:int => 3}) }.should raise_error(Sequel::Error)
      BabySitter.TroubleMaker.should eql(MyModel)
    end
  end
end
