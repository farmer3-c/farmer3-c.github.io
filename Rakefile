require "rubygems"
require 'rake'
require 'yaml'
require 'time'
require 'highline/import'

SOURCE = "."
CONFIG = {
  'version' => "12.3.2",
  'themes' => File.join(SOURCE, "_includes", "themes"),
  'layouts' => File.join(SOURCE, "_layouts"),
  'posts' => File.join(SOURCE, "_posts"),
  'post_ext' => "md",
  'theme_package_version' => "0.1.0"
}

# Usage: rake post title="A Title" subtitle="A sub title"
desc "Begin a new post in #{CONFIG['posts']}"
task :post do
  abort("rake aborted: '#{CONFIG['posts']}' directory not found.") unless FileTest.directory?(CONFIG['posts'])
  title = ENV["title"] || "new-post"
  subtitle = ENV["subtitle"] || " "
  slug = title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  begin
    date = (ENV['date'] ? Time.parse(ENV['date']) : Time.now).strftime('%Y-%m-%d')
  rescue Exception => e
    puts "Error - date format must be YYYY-MM-DD, please check you typed it correctly!"
    exit -1
  end
  
  # 查找同一天的所有文件并确定下一个编号
  base_filename = File.join(CONFIG['posts'], "#{date}-#{slug}")
  existing_files = Dir.glob(File.join(CONFIG['posts'], "#{date}-#{slug}*.md"))
  
  if existing_files.empty?
    # 如果没有同名文件，使用基本文件名
    filename = "#{base_filename}.#{CONFIG['post_ext']}"
  else
    # 查找现有的编号
    numbers = existing_files.map do |file|
      if file =~ /#{Regexp.escape(base_filename)}-(\d+)\.md$/
        $1.to_i
      else
        0 # 没有编号的文件视为编号0
      end
    end
    
    # 确定下一个编号
    next_number = numbers.max + 1
    filename = "#{base_filename}-#{next_number}.#{CONFIG['post_ext']}"
  end
  
  if File.exist?(filename)
    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
  end

  puts "Creating new post: #{filename}"
  open(filename, 'w') do |post|
    post.puts "---"
    post.puts "layout: post"
    post.puts "title: \"#{title.gsub(/-/,' ')}\""
    post.puts "subtitle: \"#{subtitle.gsub(/-/,' ')}\""
    post.puts "date: #{Time.now.strftime('%Y-%m-%d %H:%M:%S %z')}"
    post.puts "author: \"farmer3-c\""
    post.puts "header-img: \"img/post-bg-2015.jpg\""
    post.puts "tags: []"
    post.puts "mathjax: true"
    post.puts "---"
  end
end # task :post

desc "Launch preview environment"
task :preview do
  system "jekyll --auto --server"
end # task :preview

#Load custom rake scripts
Dir['_rake/*.rake'].each { |r| load r }