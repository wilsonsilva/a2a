# frozen_string_literal: true

require 'json'
require 'time'
require 'securerandom'
require 'base64'
require 'uri'
require 'rack'
require 'readline'
require 'pastel'

require_relative '../a2a'

module A2A
  # Command-line interface for interacting with A2A agents
  class CLI
    def initialize
      @current_task_id = SecureRandom.uuid
      @server_url = ARGV[0] || 'http://localhost:41241'
      @client = Client.new(base_url: @server_url)
      @agent_name = 'Agent' # Default, try to get from agent card later
      @pastel = Pastel.new
    end

    def start
      display_welcome_message
      fetch_and_display_agent_card
      display_start_info

      # Main input loop
      setup_readline

      loop do
        prompt = "#{@pastel.cyan("#{@agent_name} > You:")} "
        input = Readline.readline(prompt, true)
        break if input.nil?
        next if input.strip.empty?

        if input.strip.downcase == '/new'
          start_new_task
          next
        end

        send_message(input)
      end

      display_exit_message
    end

    private

    def display_welcome_message
      puts @pastel.bold('A2A Terminal Client')
      puts @pastel.dim("Agent URL: #{@server_url}")
    end

    def display_start_info
      puts @pastel.dim("Starting Task ID: #{@current_task_id}")
      puts @pastel.bright_black("Enter messages, or use '/new' to start a new task.")
    end

    def display_exit_message
      puts @pastel.yellow("\nExiting terminal client. Goodbye!")
      exit(0)
    end

    def setup_readline
      Readline.completion_proc = proc { |_s| [] }
      Readline.completion_append_character = nil
    end

    def start_new_task
      @current_task_id = SecureRandom.uuid
      puts @pastel.bold("✨ Starting new Task ID: #{@current_task_id}")
    end

    def send_message(text)
      params = TaskSendParams.new(
        id: @current_task_id,
        message: Message.new(
          role: 'user',
          parts: [TextPart.new(text: text)]
        )
      )

      begin
        puts @pastel.bright_black('Sending...')

        @client.send_task_subscribe(params) do |event|
          print_agent_event(event)
        end

        puts @pastel.dim('--- End of response for this input ---')
      rescue StandardError => e
        print_error(e)
      end
    end

    def print_error(error)
      puts @pastel.red("\n❌ Error communicating with agent (#{@agent_name}):")
      puts error.message

      puts @pastel.bright_black("   Code: #{error.code}") if error.respond_to?(:code) && error.code

      return unless error.respond_to?(:data) && error.data

      puts @pastel.bright_black("   Data: #{JSON.pretty_generate(error.data)}")
    end

    def print_agent_event(event)
      timestamp = Time.now.strftime('%H:%M:%S')
      prefix = @pastel.magenta("\n#{@agent_name} [#{timestamp}]:")

      case event
      when TaskStatusUpdateEvent
        print_status_update(event, prefix)
      when TaskArtifactUpdateEvent
        print_artifact_update(event, prefix)
      else
        puts "#{prefix} #{@pastel.yellow("Received unknown event type:")} #{event.inspect}"
      end
    end

    def print_status_update(event, prefix)
      state = event.status.state
      state_emoji, state_color = state_indicator(state)

      puts "#{prefix} #{state_emoji} Status: #{@pastel.send(state_color, state)}"

      print_message_content(event.status.message) if event.status.message
    end

    def print_artifact_update(event, prefix)
      artifact = event.artifact
      name = artifact.name || '(unnamed)'
      index = artifact.index || 0

      puts "#{prefix} 📄 Artifact Received: #{name} (Index: #{index})"

      message = Message.new(role: 'agent', parts: artifact.parts)
      print_message_content(message)
    end

    def state_indicator(state)
      case state
      when 'working'
        ['⏳', :blue]
      when 'input-required'
        ['🤔', :yellow]
      when 'completed'
        ['✅', :green]
      when 'canceled'
        ['⏹️', :bright_black]
      when 'failed'
        ['❌', :red]
      else
        ['❓', :yellow]
      end
    end

    def print_message_content(message)
      message.parts.each_with_index do |part, index|
        part_prefix = @pastel.bright_black("  Part #{index + 1}:")

        case part
        when TextPart
          puts "#{part_prefix} #{@pastel.green("📝 Text:")} #{part.text}"
        when FilePart
          print_file_part(part, part_prefix)
        when DataPart
          puts "#{part_prefix} #{@pastel.yellow("📊 Data:")}"
          puts JSON.pretty_generate(part.data)
        end
      end
    end

    def print_file_part(part, prefix)
      file = part.file
      name = file.name || 'N/A'
      type = file.mime_type || 'N/A'
      source = file.bytes ? 'Inline (bytes)' : file.uri

      puts "#{prefix} #{@pastel.blue("📄 File:")} Name: #{name}, Type: #{type}, Source: #{source}"
    end

    def fetch_and_display_agent_card
      well_known_url = URI.join(@server_url, '/.well-known/agent.json').to_s
      puts @pastel.dim("Attempting to fetch agent card from: #{well_known_url}")

      begin
        card = @client.agent_card
        update_agent_info(card)
        display_agent_card(card)
      rescue StandardError => e
        puts @pastel.yellow("⚠️ Error fetching agent card: #{e.message}")
      end
    end

    def update_agent_info(card)
      @agent_name = card.name || 'Agent'
    end

    def display_agent_card(card)
      puts @pastel.green('✓ Agent Card Found:')
      puts "  Name:        #{@pastel.bold(@agent_name)}"
      puts "  Description: #{card.description}" if card.description
      puts "  Version:     #{card.version || "N/A"}"
    end
  end
end
