#!/usr/bin/env ruby
# Test script for Google Pixel slow motion video implementation
# Run with: bundle exec ruby test_speed_segments.rb

require_relative 'config/environment'

class SpeedSegmentTester
  def self.run_all_tests
    puts "🧪 Testing Google Pixel Slow Motion Video Implementation"
    puts "=" * 60
    
    new.run_tests
  end
  
  def run_tests
    test_dependencies
    test_models
    test_services
    test_controllers
    test_database
    
    puts "\n✅ All tests completed!"
  end
  
  private
  
  def test_dependencies
    puts "\n1. Testing Dependencies..."
    
    # Test FFprobe
    if system('which ffprobe > /dev/null 2>&1')
      puts "  ✅ FFprobe is available"
    else
      puts "  ❌ FFprobe not found. Install with: sudo apt-get install ffmpeg"
    end
    
    # Test database connection
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      puts "  ✅ Database connection working"
    rescue => e
      puts "  ❌ Database connection failed: #{e.message}"
    end
  end
  
  def test_models
    puts "\n2. Testing Models..."
    
    # Test VideoSpeedSegment model
    if defined?(VideoSpeedSegment)
      puts "  ✅ VideoSpeedSegment model exists"
      
      # Test validations
      segment = VideoSpeedSegment.new
      if segment.valid?
        puts "  ❌ VideoSpeedSegment should have validation errors"
      else
        puts "  ✅ VideoSpeedSegment validations working"
      end
    else
      puts "  ❌ VideoSpeedSegment model not found"
    end
    
    # Test Item model integration
    if Item.method_defined?(:video_speed_segments)
      puts "  ✅ Item has video_speed_segments association"
    else
      puts "  ❌ Item missing video_speed_segments association"
    end
    
    if Item.method_defined?(:has_slow_motion?)
      puts "  ✅ Item has has_slow_motion? method"
    else
      puts "  ❌ Item missing has_slow_motion? method"
    end
  end
  
  def test_services
    puts "\n3. Testing Services..."
    
    if defined?(VideoMetadataExtractor)
      puts "  ✅ VideoMetadataExtractor service exists"
      
      # Test with a video item if available
      video_item = Item.where(variety: 'video').first
      if video_item
        begin
          extractor = VideoMetadataExtractor.new(video_item)
          metadata = extractor.extract_metadata
          puts "  ✅ VideoMetadataExtractor can extract metadata"
          puts "    - Basic info: #{metadata[:basic_info] ? 'Yes' : 'No'}"
          puts "    - Is Pixel slow motion: #{metadata[:is_pixel_slow_motion] ? 'Yes' : 'No'}"
        rescue => e
          puts "  ❌ VideoMetadataExtractor failed: #{e.message}"
        end
      else
        puts "  ⚠️  No video items available for testing"
      end
    else
      puts "  ❌ VideoMetadataExtractor service not found"
    end
  end
  
  def test_controllers
    puts "\n4. Testing Controllers..."
    
    if defined?(VideoSpeedSegmentsController)
      puts "  ✅ VideoSpeedSegmentsController exists"
      
      # Test controller methods
      controller = VideoSpeedSegmentsController.new
      methods = ['index', 'show', 'create', 'update', 'destroy', 'extract']
      methods.each do |method|
        if controller.respond_to?(method, true)
          puts "  ✅ #{method} action exists"
        else
          puts "  ❌ #{method} action missing"
        end
      end
    else
      puts "  ❌ VideoSpeedSegmentsController not found"
    end
  end
  
  def test_database
    puts "\n5. Testing Database..."
    
    begin
      # Check if video_speed_segments table exists
      if ActiveRecord::Base.connection.table_exists?('video_speed_segments')
        puts "  ✅ video_speed_segments table exists"
        
        # Check table structure
        columns = ActiveRecord::Base.connection.columns('video_speed_segments')
        required_columns = ['item_id', 'start_time', 'end_time', 'playback_rate', 'source_type', 'metadata']
        
        required_columns.each do |column|
          if columns.any? { |c| c.name == column }
            puts "  ✅ #{column} column exists"
          else
            puts "  ❌ #{column} column missing"
          end
        end
        
        # Check indexes
        indexes = ActiveRecord::Base.connection.indexes('video_speed_segments')
        puts "  ✅ #{indexes.count} indexes found"
        
      else
        puts "  ❌ video_speed_segments table not found"
        puts "     Run: bundle exec rails db:migrate"
      end
    rescue => e
      puts "  ❌ Database test failed: #{e.message}"
    end
  end
end

# Run tests if this file is executed directly
if __FILE__ == $0
  SpeedSegmentTester.run_all_tests
end