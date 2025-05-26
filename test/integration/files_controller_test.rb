require "test_helper"

class FilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users :one
    @password = "password123"
    @user.update! password: @password

    @file_info = {
      path: "/test/file.txt",
      mtime: (Time.current.to_f * 1000).round,
      size: 1024,
      sha256: "a" * 64  # Mock SHA256 hash
    }

    # Mock Bucket class
    Object.const_set(:Bucket, Class.new do
      def self.put_object key:, body:, metadata:
        true
      end
    end) unless defined?(Bucket)
  end

  test "authentication flow" do
    # Test authentication
    post "/files/auth", params: {
      username: @user.username,
      password: @password,
      nickname: "Test Device",
      os: "Linux",
      client_software: "Test Client",
      client_version: "1.0"
    }.to_json, headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :success
    response_data = JSON.parse @response.body
    assert response_data["token"].present?
    @token = response_data["token"]

    # Verify device was created
    device = Device.last
    assert_equal @user.id, device.user_id
    assert_equal "Test Device", device.nickname
    assert_equal "Linux", device.os
  end

  test "complete file upload flow" do
    # Step 1: Authenticate
    post "/files/auth", params: {
      username: @user.username,
      password: @password,
      nickname: "Test Device",
      os: "Linux",
      client_software: "Test Client",
      client_version: "1.0"
    }.to_json, headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :success
    response_data = JSON.parse @response.body
    @token = response_data["token"]

    # Step 2: Send manifest
    post "/files/manifest", params: [@file_info].to_json, headers: {
      "CONTENT_TYPE" => "application/json",
      "Authorization" => "Bearer #{@token}",
      "X-API-Version" => "1.0"
    }

    assert_response :success
    manifest_response = JSON.parse @response.body
    assert_equal 1, manifest_response.length
    assert_equal @file_info[:path], manifest_response[0]["path"]

    # Step 3: Send hashes
    post "/files/hashes", params: [@file_info].to_json, headers: {
      "CONTENT_TYPE" => "application/json",
      "Authorization" => "Bearer #{@token}",
      "X-API-Version" => "1.0"
    }

    assert_response :success
    hashes_response = JSON.parse @response.body
    assert_equal 1, hashes_response.length
    assert_equal @file_info[:path], hashes_response[0]["path"]

    # Step 4: Upload file
    content = "test content"
    put "/files/upload", params: content, headers: {
      "CONTENT_TYPE" => "application/octet-stream",
      "Authorization" => "Bearer #{@token}",
      "X-API-Version" => "1.0",
      "X-Path" => @file_info[:path],
      "X-MTime" => @file_info[:mtime],
      "X-SHA256" => Digest::SHA256.hexdigest(content),
      "X-Size" => content.size
    }

    assert_response :success

    # Verify the blob was created
    blob = CheeseBlob.find_by(path: @file_info[:path])
    assert blob.present?
    assert_equal Digest::SHA256.hexdigest(content), blob.sha256
    assert_equal content.size, blob.size
  end

  test "invalid authentication" do
    post "/files/auth", params: {
      username: @user.username,
      password: "wrong_password",
      nickname: "Test Device",
      os: "Linux",
      client_software: "Test Client",
      client_version: "1.0"
    }.to_json, headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :unauthorized
  end

  test "invalid api version" do
    post "/files/auth", params: {
      username: @user.username,
      password: @password,
      nickname: "Test Device",
      os: "Linux",
      client_software: "Test Client",
      client_version: "1.0"
    }.to_json, headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :success
    response_data = JSON.parse @response.body
    @token = response_data["token"]

    post "/files/manifest", params: [@file_info].to_json, headers: {
      "CONTENT_TYPE" => "application/json",
      "Authorization" => "Bearer #{@token}",
      "X-API-Version" => "2.0"
    }

    assert_response :internal_server_error
  end

  test "size mismatch in upload" do
    post "/files/auth", params: {
      username: @user.username,
      password: @password,
      nickname: "Test Device",
      os: "Linux",
      client_software: "Test Client",
      client_version: "1.0"
    }.to_json, headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :success
    response_data = JSON.parse(@response.body)
    @token = response_data["token"]

    content = "test content"
    put "/files/upload", params: content, headers: {
      "CONTENT_TYPE" => "application/octet-stream",
      "Authorization" => "Bearer #{@token}",
      "X-API-Version" => "1.0",
      "X-Path" => @file_info[:path],
      "X-MTime" => @file_info[:mtime],
      "X-SHA256" => Digest::SHA256.hexdigest(content),
      "X-Size" => content.size + 1  # Intentionally wrong size
    }

    assert_response :bad_request
    assert_equal "Size mismatch", @response.body
  end

  test "sha256 mismatch in upload" do
    post "/files/auth", params: {
      username: @user.username,
      password: @password,
      nickname: "Test Device",
      os: "Linux",
      client_software: "Test Client",
      client_version: "1.0"
    }.to_json, headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :success
    response_data = JSON.parse @response.body
    @token = response_data["token"]

    content = "test content"
    put "/files/upload", params: content, headers: {
      "CONTENT_TYPE" => "application/octet-stream",
      "Authorization" => "Bearer #{@token}",
      "X-API-Version" => "1.0",
      "X-Path" => @file_info[:path],
      "X-MTime" => @file_info[:mtime],
      "X-SHA256" => "wrong_hash",
      "X-Size" => content.size
    }

    assert_response :bad_request
    assert_equal "SHA256 mismatch", @response.body
  end
end
