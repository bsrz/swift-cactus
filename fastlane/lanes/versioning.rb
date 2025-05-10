lane :make_branch_name do |options|
  is_rollback = options.fetch(:is_rollback, false)
  semver = options[:semver]

  if semver.nil? || semver.empty?
    UI.abort_with_message! "You must pass the semantic version parameter"
  end

  # Parse major and minor versions
  components = semver.split('.')
  major = components[0].to_i
  minor = components[1].to_i

  if major == 0 && components[0] != "0"
    UI.abort_with_message! "The major version must be a Integer"
  end
  if minor == 0 && components[1] != "0"
    UI.abort_with_message! "The minor version must be a Integer"
  end

  # Create the new branch name
  prefix = is_rollback ? 'rollback' : 'release'
  branch_name = "#{prefix}/#{major}.#{minor}.x"

  UI.important "Created branch name: #{branch_name}"
  branch_name
end

lane :get_semantic_version do
  Dir.chdir(ENV['PWD']) { `agvtool mvers -terse1`.strip }
end

lane :make_release_branch do |options|
  semver = get_semantic_version
  branch_name = make_branch_name(semver: semver)

  UI.important "branch name: #{branch_name}"

  # Create the branch from main
  sh "git checkout main"
  sh "git pull origin main"
  sh "git checkout -b #{branch_name}"
  sh "git push origin #{branch_name}"
end

lane :identify_branch do |options|
  # Get all remote release branches and sort them
  branches = sh("git ls-remote --heads origin 'release/*' | sed 's/.*refs\\/heads\\///'").split("\n")
  release_branches = branches.select { |b| b.match(/^release\/\d+\.\d+\.x$/) }
  
  # Sort branches by version (assuming format is consistent)
  sorted_branches = release_branches.sort_by do |branch|
    parts = branch.gsub('release/', '').split('.')
    [parts[0].to_i, parts[1].to_i]
  end
  
  # Most recent release branch is the prerelease branch
  prerelease_branch = sorted_branches.last
  UI.message "Determined prerelease branch: #{prerelease_branch}"
  
  # Second most recent release branch is the current release branch
  release_branch = sorted_branches[-2]
  UI.message "Determined release branch: #{release_branch}"

  {
    prerelease_branch: prerelease_branch,
    release_branch: release_branch
  }
end

lane :minor_bump do |options|
  increment_version_number(bump_type: 'minor')
end

lane :run_build do |options|
  branch_name = options.fetch(:gh_branch_name, "")
  if branch_name.empty?
    UI.abort_with_message! "branch name cannot be empty"
  end

  identified_branches = identify_branch

  if branch_name == identified_branches[:prerelease_branch]
    UI.important "Running prerelease build"
  elsif branch_name == identified_branches[:release_branch]
    UI.important "Running release build"
  else
    UI.abort_with_message! "Aborting; unable to determine lane to run"
  end
end
