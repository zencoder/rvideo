require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/contrib/rubyforgepublisher'
require 'fileutils'
require 'hoe'
begin
  require 'spec/rake/spectask'
rescue LoadError
  puts 'To use rspec for testing you must install rspec gem:'
  puts '$ sudo gem install rspec'
  exit
end

include FileUtils
require File.join(File.dirname(__FILE__), 'lib', 'rvideo', 'version')

AUTHOR = 'Jonathan Dahl (Slantwise Design)'  # can also be an array of Authors
EMAIL = "jon@slantwisedesign.com"
DESCRIPTION = "Inspect and process video or audio files"
GEM_NAME = 'rvideo' # what ppl will type to install your gem

@config_file = "~/.rubyforge/user-config.yml"
@config = nil
def rubyforge_username
  unless @config
    begin
      @config = YAML.load(File.read(File.expand_path(@config_file)))
    rescue
      puts <<-EOS
ERROR: No rubyforge config file found: #{@config_file}"
Run 'rubyforge setup' to prepare your env for access to Rubyforge
 - See http://newgem.rubyforge.org/rubyforge.html for more details
      EOS
      exit
    end
  end
  @rubyforge_username ||= @config["username"]
end

RUBYFORGE_PROJECT = 'rvideo' # The unix name for your project
HOMEPATH = "http://#{RUBYFORGE_PROJECT}.rubyforge.org"
DOWNLOAD_PATH = "http://rubyforge.org/projects/#{RUBYFORGE_PROJECT}"

NAME = "rvideo"
REV = nil 
# UNCOMMENT IF REQUIRED: 
# REV = `svn info`.each {|line| if line =~ /^Revision:/ then k,v = line.split(': '); break v.chomp; else next; end} rescue nil
VERS = Rvideo::VERSION::STRING + (REV ? ".#{REV}" : "")
CLEAN.include ['**/.*.sw?', '*.gem', '.config', '**/.DS_Store']
RDOC_OPTS = ['--quiet', '--title', 'rvideo documentation',
    "--opname", "index.html",
    "--line-numbers", 
    "--main", "README",
    "--inline-source"]

class Hoe
  def extra_deps 
    @extra_deps.reject { |x| Array(x).first == 'hoe' } 
  end 
end

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
hoe = Hoe.new(GEM_NAME, VERS) do |p|
  p.author = AUTHOR 
  p.description = DESCRIPTION
  p.email = EMAIL
  p.summary = DESCRIPTION
  p.url = HOMEPATH
  p.rubyforge_name = RUBYFORGE_PROJECT if RUBYFORGE_PROJECT
  p.test_globs = ["test/**/test_*.rb"]
  p.clean_globs |= CLEAN  #An array of file patterns to delete on clean.
  
  # == Optional
  p.changes = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  #p.extra_deps = []     # An array of rubygem dependencies [name, version], e.g. [ ['active_support', '>= 1.3.1'] ]
  #p.spec_extras = {}    # A hash of extra values to set in the gemspec.
end

CHANGES = hoe.paragraphs_of('History.txt', 0..1).join("\n\n")
PATH    = (RUBYFORGE_PROJECT == GEM_NAME) ? RUBYFORGE_PROJECT : "#{RUBYFORGE_PROJECT}/#{GEM_NAME}"
hoe.remote_rdoc_dir = File.join(PATH.gsub(/^#{RUBYFORGE_PROJECT}\/?/,''), 'rdoc')

desc 'Generate website files'
task :website_generate do
  Dir['website/**/*.txt'].each do |txt|
    sh %{ ruby scripts/txt2html #{txt} > #{txt.gsub(/txt$/,'html')} }
  end
end

desc 'Upload website files to rubyforge'
task :website_upload do
  host = "#{rubyforge_username}@rubyforge.org"
  remote_dir = "/var/www/gforge-projects/#{PATH}/"
  local_dir = 'website'
  sh %{rsync -aCv #{local_dir}/ #{host}:#{remote_dir}}
end

desc 'Generate and upload website files'
task :website => [:website_generate, :website_upload, :publish_docs]

desc 'Release the website and new gem version'
task :deploy => [:check_version, :website, :release] do
  puts "Remember to create SVN tag:"
  puts "svn copy svn+ssh://#{rubyforge_username}@rubyforge.org/var/svn/#{PATH}/trunk " +
    "svn+ssh://#{rubyforge_username}@rubyforge.org/var/svn/#{PATH}/tags/REL-#{VERS} "
  puts "Suggested comment:"
  puts "Tagging release #{CHANGES}"
end

desc 'Runs tasks website_generate and install_gem as a local deployment of the gem'
task :local_deploy => [:website_generate, :install_gem]

task :check_version do
  unless ENV['VERSION']
    puts 'Must pass a VERSION=x.y.z release version'
    exit
  end
  unless ENV['VERSION'] == VERS
    puts "Please update your version.rb to match the release version, currently #{VERS}"
    exit
  end
end

#require 'rake'
#require 'spec/rake/spectask'
require File.dirname(__FILE__) + '/lib/rvideo'

namespace :spec do
  desc "Run Unit Specs"
  Spec::Rake::SpecTask.new("units") do |t| 
    t.spec_files = FileList['spec/units/**/*.rb']
  end

  desc "Run Integration Specs"
  Spec::Rake::SpecTask.new("integrations") do |t| 
    t.spec_files = FileList['spec/integrations/**/*.rb']
  end
end

desc "Process a file"
task(:transcode) do
  RVideo::Transcoder.logger = Logger.new(STDOUT)
  transcode_single_job(ENV['RECIPE'], ENV['FILE'])
end

desc "Batch transcode files"
task(:batch_transcode) do
  RVideo::Transcoder.logger = Logger.new(File.dirname(__FILE__) + '/test/output.log')
  f = YAML::load(File.open(File.dirname(__FILE__) + '/test/batch_transcode.yml'))
  recipes = f['recipes']
  files = f['files']
  files.each do |f|
    file = "#{File.dirname(__FILE__)}/test/files/#{f}"
    recipes.each do |recipe|
      transcode_single_job(recipe, file)
    end
  end
end

def transcode_single_job(recipe, input_file)
  puts "Transcoding #{File.basename(input_file)} to #{recipe}"
  r = YAML::load(File.open(File.dirname(__FILE__) + '/test/recipes.yml'))[recipe]
  transcoder = RVideo::Transcoder.new(input_file)
  output_file = "#{TEMP_PATH}/#{File.basename(input_file, ".*")}-#{recipe}.#{r['extension']}"
  FileUtils.mkdir_p(File.dirname(output_file))
  begin
    transcoder.execute(r['command'], {:output_file => output_file}.merge(r))
    puts "Finished #{File.basename(output_file)} in #{transcoder.total_time}"
  rescue StandardError => e
    puts "Error transcoding #{File.basename(output_file)} - #{e.class} (#{e.message}\n#{e.backtrace})"
  end
end
