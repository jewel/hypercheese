namespace :files do
  desc "Check all files for changes and reimport as needed"
  task :check_and_reimport => :environment do
    puts "Starting file reimport check..."
    
    result = Import.check_and_reimport_all
    
    puts "\nFile reimport completed!"
    puts "Summary:"
    puts "  Files checked: #{ItemPath.count}"
    puts "  Files changed: #{result[:changed_files].count}"
    puts "  Items split: #{result[:split_items].count}"
    puts "  Items reimported: #{result[:reimported_items].count}"
    
    if result[:changed_files].any?
      puts "\nChanged files:"
      result[:changed_files].each do |item_path|
        puts "  #{item_path.path_with_source}"
      end
    end
    
    if result[:split_items].any?
      puts "\nSplit items:"
      result[:split_items].each do |split_info|
        puts "  #{split_info[:moved_path].path_with_source} -> new item #{split_info[:new_item].id}"
      end
    end
  end

  desc "Check a specific file path for changes"
  task :check_path, [:path] => :environment do |t, args|
    unless args[:path]
      puts "Usage: rake files:check_path[/path/to/file]"
      exit 1
    end
    
    puts "Checking path: #{args[:path]}"
    Import.check_and_reimport_path(args[:path])
    puts "Check completed."
  end

  desc "Initialize file tracking for existing items"
  task :initialize_tracking => :environment do
    puts "Initializing file tracking for existing items..."
    
    count = 0
    ItemPath.where(mtime: nil).find_each do |item_path|
      if item_path.file_exists?
        item_path.update_file_stats!
        count += 1
        puts "  Updated #{item_path.path_with_source}" if count % 100 == 0
      else
        puts "  File not found: #{item_path.path_with_source}"
      end
    end
    
    puts "Initialized tracking for #{count} files."
  end

  desc "Show file tracking statistics"
  task :stats => :environment do
    total_paths = ItemPath.count
    tracked_paths = ItemPath.where.not(mtime: nil).count
    untracked_paths = total_paths - tracked_paths
    
    puts "File tracking statistics:"
    puts "  Total file paths: #{total_paths}"
    puts "  Tracked file paths: #{tracked_paths}"
    puts "  Untracked file paths: #{untracked_paths}"
    puts "  Tracking coverage: #{(tracked_paths.to_f / total_paths * 100).round(2)}%"
    
    if untracked_paths > 0
      puts "\nRun 'rake files:initialize_tracking' to initialize tracking for existing files."
    end
  end
end