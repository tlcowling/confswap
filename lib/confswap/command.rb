require 'clamp'
require 'confswap'

module Confswap
  class Command < Clamp::Command

    def initialize(*args)
      super(*args)	
    end

    def help(*args)
      return [
        "This is confswap version #{Confswap::VERSION}",
        super
      ].join("\n")
    end

    def run(*args)
      super(*args)
    end

    def execute
       if version?
         puts Confswap::VERSION
         return 0 
       end

       if configuration_filename.nil?
         puts 'Specify a template file or use --help for usage information'
         return 0
       end

       if File.exists? configuration_filename
         swap_config configuration_filename
         return 0
       else
         puts "Error: Configuration template file with name #{configuration_filename} does not exist"
         return 1
       end
    end

    def swap_config configuration_filename
      output_filename_default = configuration_filename + '.out' if output_filename.nil?

      configuration_template = Confswap::ConfigurationFileReader.read configuration_filename
      env_variables = Confswap::EnvironmentVariableReader.read_variables

      if (!property_file.nil?) || (File.exists? property_file)
        puts 'pfile specified'
        env_variables = Confswap::PropertyFileVariableReader.read_variables_from_file property_file
        p env_variables
      end
      
      begin
        output = configuration_template % env_variables
      rescue KeyError => error
        puts "#{error.message}.  Your configuration specifies this variable, but it was not found as an environment variable."
        exit(1)
      end

      write_file output, output_filename || output_filename_default
    end

    def write_file output_file_contents, output_filename
      return File.write output_filename, output_file_contents unless File.exists? output_filename
      
      if File.exists? output_filename and force?
        puts "Overwriting #{output_filename}..."
        File.write output_filename, output_file_contents
      else
        puts "#{output_filename} already exists, use the --force flag to overwrite"
      end
    end

    option ['-p', '--property-file'], "FILE PATH", 'A path to a property file to use for your template variables', :attribute_name => :property_file
    option ['-e', '--envvar'], "VARIABLE", 'Specify one or more additional environment variables', :multivalued => true
    option ['-f','--force'], :flag, "Overwrite file if it already exists", :attribute_name => :force
    option ['-v', '--version'], :flag, "The version of confswap you are running", :attribute_name => :version
    option ['-o', '--output'], "FILE PATH", "Specifies the filepath for the file", :attribute_name => :output_filename
    option ['--verbose'], :flag, "Be more verbose"
    parameter "[TEMPLATE_FILE]", "Path to the configuration file", :attribute_name => :configuration_filename
  end
end
