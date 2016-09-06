#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/helpers'
Bundler.require(:default)


# Load the library data
data = JSON.parse(
  File.read('library_index_with_github.json'),
  {:symbolize_names => true}
)

# Load the ERB templates
Templates = {}
Dir.foreach('views') do |filename|
  if filename =~ /^(\w+)\.(\w+)\.erb$/
    template_key = $1.to_sym
    Templates[template_key] = Tilt::ErubisTemplate.new(
      "views/#{filename}",
      :escape_html => true
    )
  end
end

def render(filename, template, args={})
  publicpath = "public/#{filename}"
  dirname = File.dirname(publicpath)
  FileUtils.mkdir_p(dirname) unless Dir.exist?(dirname)

  args[:url] ||= "http://www.arduinolibraries.info/#{filename}".sub!(%r|/index.html$|, '')
  args[:description] ||= nil
  args[:jsonld] ||= nil
  
  File.open(publicpath, 'wb') do |file|
    file.write Templates[:layout].render(self, args) {
      Templates[template].render(self, args)
    }
  end
end

def library_sort(libraries, key, limit=10)
  libraries.values.
    reject {|library| library[key].nil?}.
    sort_by {|library| library[key]}.
    reverse.
    slice(0, limit)
end


@count = data[:libraries].keys.count
@types = data[:types]
@categories = data[:categories]
@architectures = data[:architectures]
@authors = data[:authors]

render(
  'index.html',
  :index,
  :title => "Arduino Library List",
  :description => "A catalogue of the #{@count} Arduino Libraries",
  :most_recent => library_sort(data[:libraries], :release_date),
  :most_stars => library_sort(data[:libraries], :stargazers_count),
  :most_forked => library_sort(data[:libraries], :forks)
)

render(
  'libraries/index.html',
  :list,
  :title => 'All Libraries',
  :synopsis => "A list of the <i>#{@count}</i> "+
               "libraries registered in the Arduino Library Manager.",
  :keys => data[:libraries].keys,
  :libraries => data[:libraries]
)

data[:types].each_pair do |type,libraries|
  render(
    "types/#{type.to_s.keyize}/index.html",
    :list,
    :title => type,
    :synopsis => "A list of the <i>#{libraries.count}</i> "+
                 "libraries of the type #{type}.",
    :keys => libraries.map {|key| key.to_sym},
    :libraries => data[:libraries]
  )
end

data[:categories].each_pair do |category,libraries|
  render(
    "categories/#{category.to_s.keyize}/index.html",
    :list,
    :title => category,
    :synopsis => "A list of the <i>#{libraries.count}</i> "+
                 "libraries in the category #{category}.",
    :keys => libraries.map {|key| key.to_sym},
    :libraries => data[:libraries]
  )
end

data[:architectures].each_pair do |architecture,libraries|
  render(
    "architectures/#{architecture.to_s.keyize}/index.html",
    :list,
    :title => architecture.capitalize,
    :synopsis => "A list of the <i>#{libraries.count}</i> "+
                 "libraries in the architecture #{architecture}.",
    :keys => libraries.map {|key| key.to_sym},
    :libraries => data[:libraries]
  )
end

render(
  "authors/index.html",
  :authors,
  :title => "List of Aurduino Library Authors",
  :authors => data[:authors]
)

data[:authors].each_pair do |username,author|
  render(
    "authors/#{username}/index.html",
    :author,
    :title => author[:names].first,
    :username => username,
    :author => author,
    :libraries => data[:libraries]
  )
end

data[:libraries].each_pair do |key,library|
  jsonld = File.read("public/libraries/#{key}.json")

  render(
    "libraries/#{key}/index.html",
    :show,
    :title => library[:name],
    :description => library[:sentence],
    :jsonld => jsonld,
    :library => library
  )
end
