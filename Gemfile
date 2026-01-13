source 'https://rubygems.org'

# 使用GitHub Pages官方gem（自动包含兼容版本的Jekyll）
# 明确指定最低兼容Ruby 3.x的版本（228+），避免解析到老旧版本20
gem 'github-pages', '>= 228', group: :jekyll_plugins

# 本地开发需要的gems
gem 'jekyll-paginate'
gem 'webrick', '~> 1.7'  # 仅本地开发需要

# 开发依赖
group :development do
  gem 'rake'
end