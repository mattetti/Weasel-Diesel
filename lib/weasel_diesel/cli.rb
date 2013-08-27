require "thor"
require_relative "../weasel_diesel"

class WeaselDiesel
  class Cli < Thor
    include Thor::Actions
    namespace :weasel_diesel

    desc "generate_doc SOURCE_PATH DESTINATION_PATH", "Generate HTML documentation for WeaselDiesel web services"
    def generate_doc(source_path, destination_path="doc")
      Dir.glob(File.join(destination_root, source_path, "**", "*.rb")).each do |api|
        require api
      end

      require 'fileutils'
      destination = File.join(destination_root, destination_path)
      FileUtils.mkdir_p(destination) unless File.exist?(destination)
      File.open("#{destination}/index.html", "w"){|f| f << doc_template.result(binding)}
      puts "Documentation available there: #{destination}/index.html"
      `open #{destination}/index.html` if RUBY_PLATFORM =~ /darwin/ && !ENV['DONT_OPEN']
    end

    private

    def response_element_html(el)
      response_element_template.result(binding)
    end

    def input_params_html(required, optional)
      input_params_template.result(binding)
    end

    def input_params_template
      file = resources.join '_input_params.erb'
      ERB.new File.read(file)
    end

    def response_element_template
      file = resources.join '_response_element.erb'
      ERB.new File.read(file)
    end

    def doc_template
      file = resources.join 'template.erb'
      ERB.new File.read(file)
    end

    def resources
      require 'pathname'
      @resources ||= Pathname.new(File.join(File.dirname(__FILE__), 'doc_generator'))
    end

  end

end
