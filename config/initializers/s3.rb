class Bucket
  class << self
    def method_missing name, *args, &block
      @bucket ||= setup_bucket
      @bucket.send name, *args, &block
    end

    private
    def setup_bucket
      require 'aws-sdk-s3'

      Aws.config.update({
        region: Rails.env.production? ? 'us-east-1' : 'us-east-1',
        credentials: Aws::Credentials.new(
          Rails.env.production? ? ENV['AWS_ACCESS_KEY_ID'] : 'minioadmin',
          Rails.env.production? ? ENV['AWS_SECRET_ACCESS_KEY'] : 'minioadmin'
        ),
        endpoint: Rails.env.production? ? nil : 'http://localhost:9000',
        force_path_style: true,
      })

      bucket_name = Rails.env.production? ? ENV['AWS_BUCKET_NAME'] : 'hypercheese'
      bucket = Aws::S3::Resource.new.bucket bucket_name

      # Ensure bucket exists in development
      if Rails.env.development?
        bucket.create unless bucket.exists?
      end

      bucket
    end
  end
end
