# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

# Movie information agent using TMDB API
class MovieAgent < BaseAgent
  # Initialize the movie agent
  # @param api_key [String] TMDB API key
  # @param options [Hash] Additional options
  def initialize(api_key, options = {})
    super('Movie Agent', 'An agent that can answer questions about movies using TMDB', options)

    @api_key = api_key
    @base_url = 'https://api.themoviedb.org/3'

    # Set up agent card with movie skills
    @card = create_movie_agent_card
  end

  # Process a movie-related task
  # @param context [TaskContext] The task context
  # @return [Array<Hash>] Array of updates to apply to the task
  def process(context)
    # Extract text from the user message
    user_text = context.user_message.parts
                  .select { |p| p.is_a?(A2A::Schema::TextPart) }
                  .map(&:text)
                  .join(' ')

    # Start with a working response
    updates = [working_response('Searching for movie information...')]

    begin
      # Process the query
      response = process_movie_query(user_text)
      updates << completed_response(response)
    rescue => e
      updates << failed_response("Error processing your request: #{e.message}")
    end

    updates
  end

  private

  # Process a movie-related query
  # @param query [String] The user's query
  # @return [String] Response text
  def process_movie_query(query)
    # Check for specific patterns
    if query.match?(/plot|story|about|synopsis/i) && !query.start_with?('what')
      # Movie plot query
      movie_title = extract_movie_title(query)
      return get_movie_plot(movie_title) if movie_title
    elsif query.match?(/who (?:directed|was the director of)/i)
      # Director query
      movie_title = extract_movie_title(query)
      return get_movie_director(movie_title) if movie_title
    elsif query.match?(/(?:starred in|actor in|actress in|cast of)/i)
      # Cast query
      movie_title = extract_movie_title(query)
      return get_movie_cast(movie_title) if movie_title
    elsif query.match?(/when was .+ released/i)
      # Release date query
      movie_title = extract_movie_title(query)
      return get_movie_release_date(movie_title) if movie_title
    end

    # Generic search
    search_results = search_movies(query, 3)

    if search_results.empty?
      "I couldn't find any movies matching '#{query}'. Try being more specific or check the spelling."
    else
      results_text = "Here's what I found about '#{query}':\n\n"

      search_results.each_with_index do |movie, index|
        results_text += "#{index + 1}. **#{movie['title']}** (#{movie['release_date']&.split('-')&.first || 'N/A'})\n"
        results_text += "   Rating: #{movie['vote_average']}/10\n"
        results_text += "   Overview: #{movie['overview']}\n\n"
      end

      results_text
    end
  end

  # Extract a movie title from a query
  # @param query [String] The user's query
  # @return [String, nil] The extracted movie title or nil
  def extract_movie_title(query)
    # Try various patterns to extract the movie title
    patterns = [
      /(?:the )?plot of ["']?([^"'?]+)["']?/i,
      /["']?([^"'?]+)["']? plot/i,
      /(?:about|synopsis of) ["']?([^"'?]+)["']?/i,
      /who (?:directed|was the director of) ["']?([^"'?]+)["']?/i,
      /(?:starred in|actor in|actress in|cast of) ["']?([^"'?]+)["']?/i,
      /when was ["']?([^"'?]+)["']? released/i,
      /tell me about ["']?([^"'?]+)["']?/i
    ]

    patterns.each do |pattern|
      if (match = query.match(pattern))
        return match[1].strip
      end
    end

    nil
  end

  # Search for movies by query
  # @param query [String] Search query
  # @param limit [Integer] Maximum results to return
  # @return [Array<Hash>] Movie results
  def search_movies(query, limit = 5)
    encoded_query = URI.encode_www_form_component(query)
    url = "#{@base_url}/search/movie?api_key=#{@api_key}&query=#{encoded_query}&include_adult=false"

    response = make_api_request(url)
    results = response['results'] || []
    results.first(limit)
  end

  # Get movie details by ID
  # @param movie_id [Integer] TMDB movie ID
  # @return [Hash] Movie details
  def get_movie_details(movie_id)
    url = "#{@base_url}/movie/#{movie_id}?api_key=#{@api_key}&append_to_response=credits"
    make_api_request(url)
  end

  # Get a movie's plot
  # @param movie_title [String] Movie title to search for
  # @return [String] Plot description response
  def get_movie_plot(movie_title)
    movies = search_movies(movie_title, 1)

    if movies.empty?
      return "I couldn't find a movie titled '#{movie_title}'."
    end

    movie = movies.first
    movie_id = movie['id']

    details = get_movie_details(movie_id)

    response = "**#{details['title']}** (#{details['release_date']&.split('-')&.first || 'N/A'})\n\n"
    response += "#{details['overview']}\n\n"

    if details['tagline'] && !details['tagline'].empty?
      response += "Tagline: \"#{details['tagline']}\"\n\n"
    end

    response
  end

  # Get a movie's director
  # @param movie_title [String] Movie title to search for
  # @return [String] Director information response
  def get_movie_director(movie_title)
    movies = search_movies(movie_title, 1)

    if movies.empty?
      return "I couldn't find a movie titled '#{movie_title}'."
    end

    movie = movies.first
    movie_id = movie['id']

    details = get_movie_details(movie_id)

    directors = details['credits']['crew'].select { |crew| crew['job'] == 'Director' }

    if directors.empty?
      return "I couldn't find director information for '#{details['title']}'."
    end

    if directors.size == 1
      "**#{details['title']}** (#{details['release_date']&.split('-')&.first || 'N/A'}) was directed by #{directors.first['name']}."
    else
      director_names = directors.map { |d| d['name'] }.join(', ')
      "**#{details['title']}** (#{details['release_date']&.split('-')&.first || 'N/A'}) was directed by #{director_names}."
    end
  end

  # Get a movie's cast
  # @param movie_title [String] Movie title to search for
  # @return [String] Cast information response
  def get_movie_cast(movie_title)
    movies = search_movies(movie_title, 1)

    if movies.empty?
      return "I couldn't find a movie titled '#{movie_title}'."
    end

    movie = movies.first
    movie_id = movie['id']

    details = get_movie_details(movie_id)

    cast = details['credits']['cast'].first(5)

    if cast.empty?
      return "I couldn't find cast information for '#{details['title']}'."
    end

    response = "**#{details['title']}** (#{details['release_date']&.split('-')&.first || 'N/A'}) stars:\n\n"

    cast.each do |actor|
      response += "- #{actor['name']} as #{actor['character']}\n"
    end

    if details['credits']['cast'].size > 5
      response += "\nAnd #{details['credits']['cast'].size - 5} more actors."
    end

    response
  end

  # Get a movie's release date
  # @param movie_title [String] Movie title to search for
  # @return [String] Release date information response
  def get_movie_release_date(movie_title)
    movies = search_movies(movie_title, 1)

    if movies.empty?
      return "I couldn't find a movie titled '#{movie_title}'."
    end

    movie = movies.first

    if movie['release_date'] && !movie['release_date'].empty?
      date = Date.parse(movie['release_date']) rescue nil

      if date
        "**#{movie['title']}** was released on #{date.strftime('%B %d, %Y')}."
      else
        "**#{movie['title']}** was released on #{movie['release_date']}."
      end
    else
      "I couldn't find the release date for '#{movie['title']}'."
    end
  end

  # Make a request to the TMDB API
  # @param url [String] API URL
  # @return [Hash] Parsed response
  def make_api_request(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)

    unless response.is_a?(Net::HTTPSuccess)
      raise "API request failed: #{response.code} #{response.message}"
    end

    JSON.parse(response.body)
  end

  # Create the movie agent card
  # @return [A2A::Schema::AgentCard] The agent card
  def create_movie_agent_card
    # Default capabilities
    capabilities = A2A::Schema::AgentCapabilities.new(
      streaming: @options[:streaming] || false,
      push_notifications: @options[:push_notifications] || false,
      state_transition_history: true
    )

    # Movie-specific skills
    skills = [
      A2A::Schema::AgentSkill.new(
        id: 'movie_info',
        name: 'Movie Information',
        description: 'Get details about movies, including plot, cast, directors, and release dates',
        tags: ['movies', 'film', 'entertainment'],
        examples: [
              'Tell me about the plot of Inception',
              'Who directed The Matrix?',
              'When was Jurassic Park released?',
              'Who starred in The Godfather?',
              'What movies has Christopher Nolan directed?'
            ]
      )
    ]

    # Create the card
    A2A::Schema::AgentCard.new(
      name: @name,
      description: @description,
      url: @options[:url] || 'http://localhost:41241',
      version: @options[:version] || '0.1.0',
      capabilities: capabilities,
      skills: skills,
      provider: @options[:provider] || A2A::Schema::AgentProvider.new(
        organization: 'A2A Ruby Agents',
        url: 'https://github.com/username/a2a'
      ),
      documentation_url: @options[:documentation_url],
      authentication: @options[:authentication],
      default_input_modes: @options[:default_input_modes] || ['text'],
      default_output_modes: @options[:default_output_modes] || ['text']
    )
  end
end
