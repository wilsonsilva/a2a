#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'json'
require 'net/http'
require 'uri'

# Simple A2A client for demonstration purposes
class A2AClient
  def initialize(base_url)
    @base_url = base_url
  end

  # Get agent information
  def get_agent_info
    send_request('GET', '/v1/agent/info')
  end

  # Send a task to the agent
  def send_task(params)
    send_request('POST', '/v1/task/send', { params: params })
  end

  # Get a task by ID
  def get_task(task_id)
    send_request('GET', "/v1/task/#{task_id}")
  end

  # Cancel a task by ID
  def cancel_task(task_id)
    send_request('POST', "/v1/task/#{task_id}/cancel")
  end

  # Send a streaming task and process events
  def send_streaming_task(params)
    uri = URI.parse("#{@base_url}/v1/task/send/streaming")

    # Create HTTP connection
    http = Net::HTTP.new(uri.host, uri.port)

    # Create request
    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request.body = { params: params }.to_json

    # Send request
    http.request(request) do |response|
      # Check if response is successful
      if response.code.to_i == 200
        # Process SSE events
        buffer = ""
        response.read_body do |chunk|
          buffer += chunk

          # Process complete events in the buffer
          while buffer.include?("\n\n")
            event_data, buffer = buffer.split("\n\n", 2)
            process_sse_event(event_data)
          end
        end
      else
        puts "Error: #{response.code} #{response.message}"
        puts response.body
      end
    end
  end

  private

  # Process an SSE event
  def process_sse_event(event_data)
    event_type = nil
    data = nil

    # Parse the event
    event_data.each_line do |line|
      if line.start_with?('event:')
        event_type = line.sub(/^event:\s*/, '').strip
      elsif line.start_with?('data:')
        data = line.sub(/^data:\s*/, '').strip
      end
    end

    # Skip if incomplete
    return unless event_type && data

    # Parse the JSON data
    parsed_data = JSON.parse(data)

    case event_type
    when 'taskId'
      puts "Task ID: #{parsed_data['task_id']}"
    when 'taskStatusUpdate'
      status = parsed_data['status']
      puts "Status update: #{status['state']} - #{status['message']}"
    when 'taskArtifactUpdate'
      artifact = parsed_data['artifact']
      if artifact['type'] == 'text'
        puts "Artifact received: #{artifact['data']['content']}"
      else
        puts "Artifact received: #{artifact['type']}"
      end
    end
  end

  # Send an HTTP request
  def send_request(method, path, body = nil)
    uri = URI.parse("#{@base_url}#{path}")

    # Create HTTP connection
    http = Net::HTTP.new(uri.host, uri.port)

    # Create request
    case method
    when 'GET'
      request = Net::HTTP::Get.new(uri.request_uri)
    when 'POST'
      request = Net::HTTP::Post.new(uri.request_uri)
    else
      raise "Unsupported method: #{method}"
    end

    # Set headers and body
    request['Content-Type'] = 'application/json'
    request.body = body.to_json if body

    # Send request
    response = http.request(request)

    # Parse and return response
    if response.body && !response.body.empty?
      JSON.parse(response.body)
    else
      {}
    end
  end
end

# Example usage
if __FILE__ == $PROGRAM_NAME
  client = A2AClient.new('http://localhost:3000')

  # Get agent info
  puts "Getting agent info..."
  agent_info = client.get_agent_info
  puts JSON.pretty_generate(agent_info)
  puts

  # Send a regular task
  puts "Sending echo task..."
  task_response = client.send_task({ type: 'echo', message: 'Hello, A2A!' })
  puts "Task ID: #{task_response['task_id']}"

  # Wait a moment for the task to complete
  sleep(1)

  # Get the task result
  task_result = client.get_task(task_response['task_id'])
  puts "Task status: #{task_result['task']['status']['state']}"
  if task_result['task']['artifacts'] && !task_result['task']['artifacts'].empty?
    artifact = task_result['task']['artifacts'].first
    puts "Artifact: #{artifact['data']['content']}"
  end
  puts

  # Send a streaming task
  puts "Sending streaming task (reverse)..."
  client.send_streaming_task({ type: 'reverse', text: 'Hello, Streaming A2A!' })
end
