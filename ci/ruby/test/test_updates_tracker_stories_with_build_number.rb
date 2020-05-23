require 'tmpdir'

require 'minitest/autorun'
require 'webmock/minitest'

require 'updates_tracker_stories_with_build_number'

WebMock.disable_net_connect!

class TestUpdatesTrackerStoryWithBuildNumber < MiniTest::Test
  include WebMock::Matchers
  include UpdatesTrackerStoriesWithBuildNumber

  private def git_empty_commit(message)
    system(
      'git', '-C', tmpdir, 'commit',
      '--allow-empty',
      '--message', message
    )
  end

  attr_accessor :tracker_token
  attr_accessor :build_number
  attr_accessor :tmpdir

  def setup
    @tmpdir = Dir.mktmpdir
    @tracker_token = 'tracker_token'
    @build_number = 'some build number'

    system('git', 'init', tmpdir)
    git_empty_commit('first commit')

    stub_request(:any, %r{https://www.pivotaltracker.com.*})
  end

  def test_updates_no_stories_when_no_tracker_ids_committed
    update_stories_with_build_number(
      commits: 'HEAD',
      build_number: build_number,
      tracker_token: tracker_token,
      git_dir: tmpdir
    )

    assert_not_requested(:any, %r{https://www.pivotaltracker.com.*})
  end

  def test_updates_stories_for_between_given_refs
    project_id = 9876
    story_id = 1234

    git_empty_commit("[##{story_id}] second commit")
    git_empty_commit("[Finishes ##{story_id}] second commit")

    stub_get_story_request(story_id: story_id, project_id: project_id)

    update_stories_with_build_number(
      commits: 'HEAD',
      build_number: build_number,
      tracker_token: tracker_token,
      message_template: "This was delivered in TestFlight build %<build_number>s",
      git_dir: tmpdir
    )

    assert_create_story_comment_requested(
      project_id: project_id,
      story_id: story_id,
      message: "This was delivered in TestFlight build #{build_number}"
    )
  end

  def test_updates_stories_for_multiple_tracker_projects
    project_1_id = 9876
    story_1_id = 1234

    project_2_id = 8765
    story_2_id = 2345

    git_empty_commit("[Finishes ##{story_1_id}]")
    git_empty_commit("[Finishes ##{story_2_id}]")

    stub_get_story_request(story_id: story_1_id, project_id: project_1_id)
    stub_get_story_request(story_id: story_2_id, project_id: project_2_id)

    update_stories_with_build_number(
      commits: 'HEAD',
      build_number: build_number,
      tracker_token: tracker_token,
      message_template: "This was delivered in TestFlight build %<build_number>s",
      git_dir: tmpdir
    )

    assert_create_story_comment_requested(
      project_id: project_1_id,
      story_id: story_1_id,
      message: "This was delivered in TestFlight build #{build_number}"
    )

    assert_create_story_comment_requested(
      project_id: project_2_id,
      story_id: story_2_id,
      message: "This was delivered in TestFlight build #{build_number}"
    )
  end

  def test_only_adds_a_comment_to_a_story_once
    project_id = 9876
    story_id = 1234

    git_empty_commit("[Finishes ##{story_id}] second commit")
    git_empty_commit("[Finishes ##{story_id}] finished again")

    stub_get_story_request(story_id: story_id, project_id: project_id)

    update_stories_with_build_number(
      commits: 'HEAD',
      build_number: build_number,
      tracker_token: tracker_token,
      message_template: "This was delivered in TestFlight build %<build_number>s",
      git_dir: tmpdir
    )

    assert_get_story_request(
      story_id: story_id,
      times: 1
    )

    assert_create_story_comment_requested(
      project_id: project_id,
      story_id: story_id,
      message: "This was delivered in TestFlight build #{build_number}",
      times: 1
    )
  end

  def test_works_for_multiline_commit_messages
    project_id = 9876
    story_id = 1234

    git_empty_commit(<<~MESSAGE.strip)
      A multi line commit message

      [Finishes ##{story_id}]
    MESSAGE

    stub_get_story_request(story_id: story_id, project_id: project_id)

    update_stories_with_build_number(
      commits: 'HEAD',
      build_number: build_number,
      tracker_token: tracker_token,
      message_template: "This was delivered in TestFlight build %<build_number>s",
      git_dir: tmpdir
    )

    assert_create_story_comment_requested(
      project_id: project_id,
      story_id: story_id,
      message: "This was delivered in TestFlight build #{build_number}",
      times: 1
    )
  end

  def test_matchs_finishes_keyword_when_lowercase
    project_id = 9876
    story_1_id = 1234
    story_2_id = 2345

    git_empty_commit("[finishes ##{story_1_id}]")
    git_empty_commit(<<~MESSAGE.strip)
      A multi line commit message

      [finishes ##{story_2_id}]
    MESSAGE

    stub_get_story_request(story_id: story_1_id, project_id: project_id)
    stub_get_story_request(story_id: story_2_id, project_id: project_id)

    update_stories_with_build_number(
      commits: 'HEAD',
      build_number: build_number,
      tracker_token: tracker_token,
      message_template: "This was delivered in TestFlight build %<build_number>s",
      git_dir: tmpdir
    )

    assert_create_story_comment_requested(
      project_id: project_id,
      story_id: story_1_id,
      message: "This was delivered in TestFlight build #{build_number}",
      times: 1
    )

    assert_create_story_comment_requested(
      project_id: project_id,
      story_id: story_2_id,
      message: "This was delivered in TestFlight build #{build_number}",
      times: 1
    )
  end

  private def assert_create_story_comment_requested(
    project_id:,
    story_id:,
    message:,
    times: 1
  )
    assert_requested(
      :post,
      "#{TRACKER_API}/projects/#{project_id}/stories/#{story_id}/comments",
      headers: {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'X-TrackerToken' => tracker_token,
        'Host' => URI(TRACKER_API).host,
        'User-Agent' => /.*/,
        'Accept-Encoding' => /.*/,
      },
      body: {
        :text => message
      }.to_json,
      times: times
    )
  end

  private def assert_get_story_request(
    story_id:,
    times: 1
  )
    assert_requested(
      :get,
      "#{TRACKER_API}/stories/#{story_id}",
      headers: {
        'Accept' => 'application/json',
        'X-TrackerToken' => tracker_token,
        'User-Agent' => /.*/,
        'Accept-Encoding' => /.*/,
      }
    )
  end

  private def stub_get_story_request(
    project_id:,
    story_id:
  )
    stub_request(
      :get,
      "#{TRACKER_API}/stories/#{story_id}"
    ).with(
      headers: {
        'Accept' => 'application/json',
        'X-TrackerToken' => tracker_token,
        'User-Agent' => /.*/,
        'Accept-Encoding' => /.*/,
      }
    ).to_return(
      body: { :project_id => project_id }.to_json
    )
  end
end
