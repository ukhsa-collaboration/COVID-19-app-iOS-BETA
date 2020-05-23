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
    tracker = Tracker.new(tracker_token)

    story_ids = git_logs(git_dir, commits)
      .scan(/\[Finishes #(\d+)\]/i)
      .map {|m| m[0] }
      .uniq

    story_ids.each do |story_id|
      text = message_template % { build_number: build_number }
      tracker.comment(story_id, text)
    end
  end

  private

  def git_logs(git_dir, rev_list)
    out, err, status = Open3.capture3(*%W(
      git -C #{git_dir} log --format='%B' #{rev_list}
    ))
    raise "Command failed: \n\n#{err}" if status.exitstatus !=0
    out
  end

  class Tracker
    BASE_URL = 'https://www.pivotaltracker.com/services/v5'

    def initialize(token)
      @token = token
    end

    def comment(story_id, text)
      project_id = story(story_id).fetch('project_id')
      uri = URI("#{TRACKER_API}/projects/#{project_id}/stories/#{story_id}/comments")
      body = JSON.dump({ text: text })
      Net::HTTP.post(uri, body, headers({ 'Content-Type' => 'application/json' }))
    end

    private

    def story(id)
      uri = URI("#{BASE_URL}/stories/#{id}")
      json = uri.open(headers).read
      JSON.parse(json)
    end

    def headers(headers={})
      {
        'Accept' => 'application/json',
        'X-TrackerToken' => @token,
      }.merge(headers)
    end
  end

end
