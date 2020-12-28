# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "blog-theme"
  spec.version       = "0.2.1"
  spec.authors       = ["bynx"]
  spec.email         = ["drtychai@protonmail.com"]

  spec.homepage      = "https://blog.bynx.io"
  spec.summary       = "https://blog.bynx.io"
  spec.license       = "MIT"
  spec.metadata["plugin_type"] = "theme"

  spec.files         = `git ls-files -z`.split("\x0").select do |f|
      f.match(%r{^((_data|_includes|_layouts|_sass|assets)/|(LICENSE|README|CHANGELOG)((\.(txt|md|markdown)|$)))}i)
    end

  spec.add_runtime_dependency "jekyll"
  #spec.add_runtime_dependency "jekyll-paginate"
  #spec.add_runtime_dependency "jekyll-sitemap"
  #spec.add_runtime_dependency "jekyll-feed"
  spec.add_runtime_dependency "jemoji"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
