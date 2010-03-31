module BabySitter
  def self.included(base)
    base.class_eval do
      class << self
        alias_method :orig_create, :create
      end
      alias_method :orig_save, :save
      extend  ClassMethods
      include InstanceMethods
    end
  end

  class << self
    def NewTroubleMaker(obj)
      @trouble_maker = obj
    end

    def TroubleMaker
      @trouble_maker
    end

    def TroubleHandled
      @trouble_maker = nil
    end
  end

  module ClassMethods
    def create(values = {}, init_method = nil, &block)
      values ||= {}
      orig_create(values,&init_method)
    rescue Exception 
      result = yield(self,values) if block_given? 
      BabySitter.NewTroubleMaker self and raise $! if result == :raise or !result
      retry if result == :retry
      result
    end
  end

  module InstanceMethods
    # Alas initilize will always return the object being worked on
    # If you catch an error, then an invalid object is returned
    # so no error catching when you use new, but we will still
    # set it as the trouble maker if something happens
    def initialize(values = {}, from_db = false,&block)
      values ||= {}
      super(values,from_db,&block)
    rescue Exception 
      BabySitter.NewTroubleMaker self.class and raise $! 
    end
  
    def save(*cols)
      orig_save(*cols)
    rescue Exception 
      result = yield(self.class,values) if block_given? 
      BabySitter.NewTroubleMaker self.class and raise $! if result == :raise or !result
      retry if result == :retry
      result
    end
  end
end
