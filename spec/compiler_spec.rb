require 'netlinx/compiler'
require 'test/netlinx/compilable'

describe NetLinx::Compiler do
  
  subject { compiler }
  
  let(:path) { 'spec/workspace/import-test' }
  let(:compiler) { NetLinx::Compiler.new }
  let(:compilable) { mock_compilable.new }
  
  let(:mock_compilable) {
    Class.new do
      attr_accessor :compiler_target_files
      attr_accessor :compiler_include_paths
      attr_accessor :compiler_module_paths
      attr_accessor :compiler_library_paths
      
      def initialize
        @compiler_target_files  = []
        @compiler_include_paths = []
        @compiler_module_paths  = []
        @compiler_library_paths = []
      end
    end
  }
  
  describe "mock_compilable" do
    subject { mock_compilable.new }
    include_examples "compilable"
  end
  
  let(:test_file_generator) {
    # Generates source and compiled file paths and functions
    # to aid in testing.
    Class.new do
      attr_reader :source_file
      attr_reader :compiled_files
      
      # file_name can be specified with or without the .axs extension.
      def initialize(file_name, **kvargs)
        @path = 'spec/workspace/import-test'
        
        # Strip off file extension if it exists.
        file = file_name.gsub /\.axs$/, ''
        
        # Create the full source file path.
        @source_file = "#{File.expand_path file, @path}.axs"
        
        # Create the full compiled file paths.
        @compiled_files = ['.tko', '.tkn']
          .map {|extension| @source_file.gsub(/\.axs$/, extension)}
      end
    end
  }

  
  it "raises an exception if the compiler cannot be found" do
    # Mock File.exists? to always return false (path not found).
    File.should_receive(:exists?).at_least(:once) { false }
    
    expect { NetLinx::Compiler.new(compiler_path: 'c:\this-path-does-not-exist') }
      .to raise_error NetLinx::NoCompilerError
  end
  
  it "compiles a .axs source code file" do
    files = test_file_generator.new 'source-file-plain'
    
    files.compiled_files.each do |file|
      # Delete any existing files.
      File.delete file if File.exists? file
      
      # Compiled files should not exist.
      File.exists?(file).should eq false
    end
    
    # Add source code file to the list of targets to compile.
    compilable.compiler_target_files << files.source_file
    
    # Run the compiler.
    compiler.compile compilable
    
    # Compiled files should exist.
    files.compiled_files.each do |file|
      File.exists?(file).should eq true
    end
  end
  
  it "compiles a source code file with an include" do
    files = test_file_generator.new 'source-file-include'
    
    files.compiled_files.each do |file|
      # Delete any existing files.
      File.delete file if File.exists? file
      
      # Compiled files should not exist.
      File.exists?(file).should eq false
    end
    
    # Add source code file to the list of targets to compile.
    compilable.compiler_target_files << files.source_file
    compilable.compiler_include_paths <<
      File.expand_path('include', path)
    
    # Run the compiler.
    compiler.compile compilable
    
    # Compiled files should exist.
    files.compiled_files.each do |file|
      File.exists?(file).should eq true
    end
  end
  
  it "compiles a source code file with a module" do
    files = test_file_generator.new 'source-file-module'
    
    files.compiled_files.each do |file|
      # Delete any existing files.
      File.delete file if File.exists? file
      
      # Compiled files should not exist.
      File.exists?(file).should eq false
    end
    
    # Add source code file to the list of targets to compile.
    compilable.compiler_target_files << files.source_file
    compilable.compiler_module_paths <<
      File.expand_path('module-compiled', path)
    
    # Run the compiler.
    compiler.compile compilable
    
    # Compiled files should exist.
    files.compiled_files.each do |file|
      File.exists?(file).should eq true
    end
  end
  
  # Added for issue #1
  # Projects with both include files and Duet modules fail to compile with NLRC.exe v2.1
  it "compiles a project with an include file and Duet module"
  
  it "compiles a source code file with a library"
  
  it "returns a hash of source file, compiler result, and compiler output for each source file" do
    f1 = test_file_generator.new 'compiler-result1'
    f2 = test_file_generator.new 'compiler-result2'
    
    source_files = [f1.source_file, f2.source_file]
    compiled_files = f1.compiled_files + f2.compiled_files
    
    compiled_files.each do |file|
      # Delete any existing files.
      File.delete file if File.exists? file
      
      # Compiled files should not exist.
      File.exists?(file).should eq false
    end
    
    # Add source code file to the list of targets to compile.
    compilable.compiler_target_files += source_files
    
    # Run the compiler.
    result = compiler.compile compilable
    
    # Compiled files should exist.
    compiled_files.each do |file|
      File.exists?(file).should eq true
    end
    
    # Compiler result should be an array of CompilerResult.
    result.should be_an Array
    result.first.should be_a NetLinx::CompilerResult
    
    result.count.should eq 2
    
    first = result.first
    first.target_file.should eq            f1.source_file
    first.compiler_include_paths.should eq []
    first.compiler_module_paths.should eq  []
    first.compiler_library_paths.should eq []
    first.errors.should eq                 0
    first.warnings.should eq               0
    first.success?.should eq true
    first.stream.should include 'NetLinx Compile Complete'
  end
  
  it "returns a failure result when compiling a nonexistent file" do
    file = test_file_generator.new 'this-file-does-not-exist'
    
    # The nonexistent file should not exist.
    File.exists?(file.source_file).should eq false
    
    # Add source code file to the list of targets to compile.
    compilable.compiler_target_files << file.source_file
    
    # Run the compiler.
    result = compiler.compile(compilable).first
    
    # Compiler should return an error.
    result.success?.should eq false
    result.errors.should eq   nil
    result.warnings.should eq nil
  end
  
  it "returns the correct number of errors and warnings when compiling" do
    file = test_file_generator.new 'compiler-errors'
    
    # Add source code file to the list of targets to compile.
    compilable.compiler_target_files << file.source_file
    
    # Run the compiler.
    result = compiler.compile(compilable).first
    
    # Compiler should return 2 warnings and 1 error.
    result.warnings.should eq 2
    result.errors.should eq   1
  end
  
  xit "includes the library at 'Program Files (x86)\\Common Files\\AMXShare\\SYCs' by default" do
    # TODO: Also check for 32-bit path.
    pending
  end
  
  describe "Wine" do
    let(:wine_path) { '~/.wine/drive_c/Program\ Files/Common\ Files/AMXShare/COM' }
    let(:source_file) { File.expand_path 'source-file-plain', 'spec/workspace/import-test' }
    let(:wine_command) { "wine \"#{File.expand_path('nlrc.exe', wine_path)}\" \"#{source_file}\"" }
    
    let(:io_double) {
      double().tap do |d|
        d.should_receive(:read) { '' }
        d.should_receive(:close)
      end
    }
    
    it "can execute the compiler" do
      # Add source code file to the list of targets to compile.
      compilable.compiler_target_files << source_file
      
      # Stub File.exists? to force Wine path.
      File.should_receive(:exists?).at_least(:once) do |path|
        path.include?('.wine') ? true : false
      end
      
      # Stub popen to check for correct command.
      IO.should_receive(:popen) do |cmd|
        cmd.should eq wine_command
        io_double
      end
      
      # Run the compiler.
      compiler.compile compilable
    end
  end
  
end
