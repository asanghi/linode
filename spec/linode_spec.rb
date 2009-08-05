require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')
require 'linode'

describe Linode do
  describe 'as a class' do
    it 'should be able to create a new Linode instance' do
      Linode.should respond_to(:new)
    end
  
    describe 'when creating a new Linode instance' do
      it 'should accept an arguments hash' do
        lambda { Linode.new(:api_key => 'foo') }.should_not raise_error(ArgumentError)
      end
      
      it 'should require an arguments hash' do
        lambda { Linode.new }.should raise_error(ArgumentError)
      end

      it 'should fail if no API key is given' do
        lambda { Linode.new({}) }.should raise_error(ArgumentError)        
      end
      
      it 'should return a Linode instance' do
        Linode.new(:api_key => 'foo').class.should == Linode
      end
    end
  end
end

describe 'Linode' do  
  before :each do
    @api_key = 'foo'
    @linode = Linode.new(:api_key => @api_key)
  end
  
  it 'should be able to return the API key provided at creation time' do
    @linode.api_key.should == 'foo'
  end
  
  it 'should be able to return the current API URL' do
    @linode.should respond_to(:api_url)
  end
  
  describe 'when returning the current API URL' do
    it 'should return the API URL provided at creation time if one was provided' do
      @linode = Linode.new(:api_key => @api_key, :api_url => 'https://fake.linode.com/')
      @linode.api_url.should == 'https://fake.linode.com/'
    end
    
    it 'should return the stock linode API URL if none was provided at creation time' do
      @linode = Linode.new(:api_key => @api_key)
      @linode.api_url.should == 'https://api.linode.com/'      
    end
  end
  
  it 'should be able to submit a request via the API' do
    @linode.should respond_to(:send_request)
  end
  
  describe 'when submitting a request via the API' do
    before :each do
      @json = %Q!{
      		"ERRORARRAY":[],
      		"ACTION":"test.echo",
      		"DATA":{"FOO":"bar"}
      	}!
      HTTParty.stubs(:get).returns(@json)
      @linode.stubs(:api_url).returns('https://fake.linode.com/')
    end
    
    it 'should allow a request name and a data hash' do
      lambda { @linode.send_request('test.echo', {}) }.should_not raise_error(ArgumentError)
    end
    
    it 'should require a request name and a data hash' do
      lambda { @linode.send_request('test.echo') }.should raise_error(ArgumentError)      
    end
    
    it 'should make a request to the API url' do
      @linode.stubs(:api_url).returns('https://fake.linode.com/')
      HTTParty.expects(:get).with { |path, args|
        path == 'https://fake.linode.com/'
      }.returns(@json)
      @linode.send_request('test.echo', { })
    end
    
    it 'should provide the API key when making its request' do
      HTTParty.expects(:get).with { |path, args|
        args[:query][:api_key] == @api_key
      }.returns(@json)
      @linode.send_request('test.echo', { })      
    end
    
    it 'should set the designated request method as the HTTP API action' do
      HTTParty.expects(:get).with { |path, args|
        args[:query][:api_action] == 'test.echo'
      }.returns(@json)
      @linode.send_request('test.echo', { })            
    end
    
    it 'should provide the data hash to the HTTP API request' do
      HTTParty.expects(:get).with { |path, args|
        args[:query]['foo'] == 'bar'
      }.returns(@json)
      @linode.send_request('test.echo', { 'foo' => 'bar' })                  
    end
    
    it 'should not allow overriding the API key via the data hash' do
      HTTParty.expects(:get).with { |path, args|
        args[:query][:api_key] == @api_key
      }.returns(@json)
      @linode.send_request('test.echo', { :api_key => 'h4x0r' })                        
    end
    
    it 'should not allow overriding the API action via the data hash' do
      HTTParty.expects(:get).with { |path, args|
        args[:query][:api_action] == 'test.echo'
      }.returns(@json)
      @linode.send_request('test.echo', { :api_action => 'h4x0r' })
    end
    
    it 'should fail when the request submission fails' do
      HTTParty.stubs(:get).returns(%Q!{
      		"ERRORARRAY":["failure"],
      		"ACTION":"test.echo",
      		"DATA":{"foo":"bar"}
      	}!)
      lambda { @linode.send_request('test.echo', { :api_action => 'failure' }) }.should raise_error
    end
    
    it 'should return an object with lower-cased methods for the data fields' do
      @linode.send_request('test.echo', {}).foo.should == 'bar'
    end
    
    it 'should return an object which does not respond to upper-case URLs for the data fields' do
      @linode.send_request('test.echo', {}).should_not respond_to(:FOO)
    end
  end
  
  it 'should be able to provide access to the Linode Test API' do
    @linode.should respond_to(:test)
  end
  
  describe 'when providing access to the Linode Test API' do
    it 'should allow no arguments' do
      lambda { @linode.test }.should_not raise_error(ArgumentError)
    end
    
    it 'should require no arguments' do
      lambda { @linode.test(:foo) }.should raise_error(ArgumentError)
    end
    
    it 'should return a Linode::Test instance' do
      @linode.test.class.should == Linode::Test
    end
    
    it 'should set the API key on the Linode::Test instance to be our API key' do
      @linode.test.api_key.should == @api_key
    end
    
    it 'should return the same Linode::Test instance when called again' do
      linode = Linode.new(:api_key => @api_key)
      result = linode.test
      linode.test.should == result
    end
  end

  it 'should be able to provide access to the Linode Avail API' do
    @linode.should respond_to(:avail)
  end
  
  describe 'when providing access to the Linode Avail API' do
    it 'should allow no arguments' do
      lambda { @linode.avail }.should_not raise_error(ArgumentError)
    end
    
    it 'should require no arguments' do
      lambda { @linode.avail(:foo) }.should raise_error(ArgumentError)
    end
    
    it 'should return a Linode::Test instance' do
      @linode.avail.class.should == Linode::Avail
    end
    
    it 'should set the API key on the Linode::Test instance to be our API key' do
      @linode.avail.api_key.should == @api_key
    end
    
    it 'should return the same Linode::Test instance when called again' do
      linode = Linode.new(:api_key => @api_key)
      result = linode.avail
      linode.avail.should == result
    end
  end
end
