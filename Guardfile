directories %w(. lib spec) \
 .select {|d| Dir.exists?(d) ? d : UI.warning("Directory #{d} does not exist")}

guard :bundler do
  watch('Gemfile')
end

guard :rspec, all_after_pass: false, all_on_start: false, failed_mode: :keep, cmd: 'bundle exec rspec' do
  watch(%r{^(lib|spec)/(.+?)(_spec)?\.rb}) {|m| "spec/#{m[2]}_spec.rb"}
end
