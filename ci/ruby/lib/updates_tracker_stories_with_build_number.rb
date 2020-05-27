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

    if !story_ids.empty?
      status, = tracker.me
      raise 'unable to authenticate with pivotal tracker' if status != :success
    end

    story_ids.each do |story_id|
      status, story = tracker.story(story_id)
      case status
      when :not_authorized
        warn("not authorized to get story #{story_id}")
        next
      when :not_found
        warn("could not find tracker story with id #{story_id}")
        next
      end

      project_id = story.fetch('project_id')
      text = message_template % { build_number: build_number }
      tracker.comment(project_id, story_id, text)
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

    STATUS_TO_SYM = {
      '200' => :success,
      '401' => :not_authenticated,
      '404' => :not_found,
      '403' => :not_authorized,
    }.tap do |h|
      h.default = :unknown
    end
    private_constant :STATUS_TO_SYM

    def initialize(token)
      @token = token
    end

    def comment(project_id, story_id, text)
      uri = URI("#{TRACKER_API}/projects/#{project_id}/stories/#{story_id}/comments")
      body = JSON.dump({ text: text })
      Net::HTTP.post(uri, body, headers({ 'Content-Type' => 'application/json' }))
    end

    def story(id)
      get("/stories/#{id}")
    end

    def me
      get("/me")
    end

    private
    def get(path)
      uri = URI("#{TRACKER_API}#{path}")

      req = Net::HTTP::Get.new(uri)
      headers.each do |(name, value)|
        req[name] = value
      end

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        resp = http.request(req)
        body = resp.read_body
        return STATUS_TO_SYM[resp.code],
          body.empty? ? nil : JSON.parse(body)
      end
    end

    def headers(headers={})
      {
        'Accept' => 'application/json',
        'X-TrackerToken' => @token,
      }.merge(headers)
    end
  end

end
