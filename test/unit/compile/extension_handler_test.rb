require 'test_helper'
require 'netlinx/compile/extension_handler'

describe NetLinx::Compile::ExtensionHandler do
  
  before do
    @extension_handler = @object = NetLinx::Compile::ExtensionHandler.new
  end
  
  after do
    @extension_handler = @object = nil
  end
  
  it "exposes a set of extensions that it can handle" do
    assert_respond_to @extension_handler, :extensions
    
    # Implements array methods.
    @extension_handler.extensions.count.must_equal 0
    @extension_handler.extensions.first.must_equal nil
  end
  
  it "exposes a class to handle its extensions" do
    assert_respond_to @extension_handler, :handler_class
  end
  
end