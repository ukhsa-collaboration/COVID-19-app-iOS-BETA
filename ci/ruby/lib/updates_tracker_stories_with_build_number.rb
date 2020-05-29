require 'net/http'

require 'tracker'
require 'git'

module UpdatesTrackerStoriesWithBuildNumber
  include Git

  module_function def update_stories_with_build_number(
    build_number:,
    tracker_token:,
    commits: 'HEAD..HEAD', # will cause rev-list to be empty
    message_template: 'This story was included in build %{build_number}',
    git_dir: Dir.pwd
  )
    tracker = Tracker.new(tracker_token)

    story_ids = git_logs(git_dir, commits)
      .tap {|x| p x }
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
      tracker.deliver(project_id, story_id)
    end
  end
end
