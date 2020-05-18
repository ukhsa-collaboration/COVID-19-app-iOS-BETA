require 'net/http'
require 'open-uri'
require 'open3'

TRACKER_API = 'https://www.pivotaltracker.com/services/v5'

module UpdatesTrackerStoriesWithBuildNumber
  module_function def update_stories_with_build_number(
    build_number:,
    tracker_token:,
    commits: 'HEAD..HEAD', # will cause rev-list to be empty
    message_template: 'This story was included in build %<build_number>s',
    git_dir: Dir.pwd
  )
    rev_list(git_dir, commits)
      .map { |commit_id|
        match = commit_message(git_dir, commit_id).match(/\[[Ff]inishes #(\d+)\]/)
        match ? Integer(match[1]) : nil
      }
      .compact
      .uniq
      .each do |story_id|
        create_story_comment(
          tracker_token: tracker_token,
          project_id: get_story(story_id: story_id, tracker_token: tracker_token).fetch('project_id'),
          story_id: story_id,
          text: message_template % { :build_number => build_number }
        )
      end
  end

  private def create_story_comment(
    tracker_token:,
    project_id:,
    story_id:,
    text:
  )
    Net::HTTP.post(
      URI("#{TRACKER_API}/projects/#{project_id}/stories/#{story_id}/comments"),
      {
        :text => text
      }.to_json,
      {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'X-TrackerToken' => tracker_token
      }
    )
  end

  private def get_story(
    story_id:,
    tracker_token:
  )
    JSON.parse(
      URI("#{TRACKER_API}/stories/#{story_id}").open({
        'Accept' => 'application/json',
        'X-TrackerToken' => tracker_token
      }).read
    )
  end

  private def commit_message(git_dir, commit_id)
    out, err, status = Open3.capture3(*%W(
      git -C #{git_dir} log
      --format='%B'
      --max-count=1
      #{commit_id}
    ))
    raise "Command failed: \n\n#{err}" if status.exitstatus !=0
    out
  end

  private def rev_list(git_dir, commits_spec)
    out, err, status = Open3.capture3(*%W(
      git -C #{git_dir} rev-list #{commits_spec}
    ))
    raise "Command failed: \n\n#{err}" if status.exitstatus !=0
    out.split(/\n+/)
  end
end
