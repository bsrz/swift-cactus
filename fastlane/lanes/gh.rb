lane :make_gh_release do |options|
  gh_token = options.fetch(:gh_token, ENV['GITHUB_TOKEN'])

  if gh_token.nil? || gh_token.empty?
    UI.abort_with_message! 'GitHub Personal Access Token cannot be nil or empty'
  end

  # Create and push tag if needed
  semver = get_semantic_version
  components = semver.split('.')
  components[2] = 'x'
  branch_name = "release/#{components.join('.')}"
  tag_name = "#{semver}"
  sh "git tag #{tag_name}"
  sh "git push origin #{tag_name}"

  # Use GitHub API directly with the generate_release_notes flag
  uri = URI.parse("https://api.github.com/repos/bsrz/swift-cactus/releases")
  request = Net::HTTP::Post.new(uri)
  request["Accept"] = "application/vnd.github+json"
  request["Authorization"] = "token #{gh_token}"

  request.body = {
    tag_name: tag_name,
    name: "Release #{tag_name}",
    target_commitish: branch_name,
    generate_release_notes: true 
  }.to_json

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  UI.message("GitHub Release API Response: #{response.body}")

  case response
  when Net::HTTPSuccess
    UI.success("GitHub release created successfully with auto-generated notes!")
  else
    UI.error("Failed to create GitHub release: #{response.body}")
  end
end
