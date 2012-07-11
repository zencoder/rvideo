# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rvideo}
  s.version = "0.9.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jonathan Dahl", "Slantwise Design"]
  s.date = %q{2007-09-27}
  s.description = %q{RVideo allows you to inspect and process video files.}
  s.email = %q{info@slantwisedesign.com}
  s.files = ["History.txt", "License.txt", "Rakefile", "README.txt", "RULES", "lib/rvideo/errors.rb", "lib/rvideo/float.rb", "lib/rvideo/inspector.rb", "lib/rvideo/tools/abstract_tool.rb", "lib/rvideo/tools/ffmpeg.rb", "lib/rvideo/tools/ffmpeg2theora.rb", "lib/rvideo/tools/flvtool2.rb", "lib/rvideo/tools/mencoder.rb", "lib/rvideo/tools/mp4box.rb", "lib/rvideo/tools/mp4creator.rb", "lib/rvideo/tools/mplayer.rb", "lib/rvideo/tools/yamdi.rb", "lib/rvideo/transcoder.rb", "lib/rvideo/version.rb", "lib/rvideo.rb"]
  
  s.has_rdoc = true
  s.homepage = %q{http://github.com/scottburton11/rvideo}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rvideo}
  s.rubygems_version = %q{1.3.0}
  s.summary = %q{RVideo allows you to inspect and process video files. This version has local modifications.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mime-types>, [">= 1.15"])
      s.add_runtime_dependency(%q<diff-lcs>, [">= 1.1.2"])
    else
      s.add_dependency(%q<mime-types>, [">= 1.15"])
      s.add_dependency(%q<diff-lcs>, [">= 1.1.2"])
    end
  else
    s.add_dependency(%q<mime-types>, [">= 1.15"])
    s.add_dependency(%q<diff-lcs>, [">= 1.1.2"])
  end
end
