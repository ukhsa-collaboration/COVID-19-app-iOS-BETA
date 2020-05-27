require 'tmpdir'

require 'minitest/autorun'

require 'test_support/git_test_support'
require 'test_support/tracker_webmock_support'

require 'updates_tracker_stories_with_build_number'

WebMock.disable_net_connect!

class TestUpdatesTrackerStoryWithBuildNumber < MiniTest::Test
  include GitTestSupport
  include TrackerWebmockSupport
  include UpdatesTrackerStoriesWithBuildNumber

  attr_accessor :tracker_token
  attr_accessor :build_number
  attr_accessor :tmpdir
  attr_accessor :stub_headers

  def setup
    @tmpdir = Dir.mktmpdir
    @tracker_token = 'tracker_token'
    @build_number = 'some build number'

    @stub_headers = {
      'Accept' => 'application/json',
      'X-TrackerToken' => tracker_token,
      'User-Agent' => /.*/,
      'Accept-Encoding' => /.*/,
    }

    git_init(tmpdir)

    git_empty_commit('first commit')

    stub_request(:any, %r{https://www.pivotaltracker.com.*})
    stub_me_request_200
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

  def test_fails_when_not_authenticated
    story_id = 1234
    git_empty_commit("[Finishes ##{story_id}] second commit")

    stub_me_request_401

    assert_raises(RuntimeError, 'unable to authenticate with pivotal tracker') do
      update_stories_with_build_number(
        commits: 'HEAD',
        build_number: build_number,
        tracker_token: tracker_token,
        git_dir: tmpdir
      )
    end
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

  def test_warns_for_unknown_story
    project_id = 9876
    story_1_id = 1234
    story_2_id = 2345

    git_empty_commit("[Finishes ##{story_1_id}] second commit")
    git_empty_commit("[Finishes ##{story_2_id}] another commit")

    stub_get_story_request_404(story_id: story_1_id)
    stub_get_story_request(story_id: story_2_id, project_id: project_id)

    stderr = capture_stderr do
      update_stories_with_build_number(
        commits: 'HEAD',
        build_number: build_number,
        tracker_token: tracker_token,
        message_template: "This was delivered in TestFlight build %<build_number>s",
        git_dir: tmpdir
      )
    end

    assert_equal("could not find tracker story with id 1234\n", stderr)

    assert_create_story_comment_not_requested(
      story_id: story_1_id,
    )

    assert_create_story_comment_requested(
      project_id: project_id,
      story_id: story_2_id,
      message: "This was delivered in TestFlight build #{build_number}"
    )
  end

  def test_warns_when_not_authorized_to_read_story
    project_id = 9876
    story_1_id = 1234
    story_2_id = 2345

    git_empty_commit("[Finishes ##{story_1_id}] second commit")
    git_empty_commit("[Finishes ##{story_2_id}] another commit")

    stub_get_story_request_403(story_id: story_1_id)
    stub_get_story_request(story_id: story_2_id, project_id: project_id)

    stderr = capture_stderr do
      update_stories_with_build_number(
        commits: 'HEAD',
        build_number: build_number,
        tracker_token: tracker_token,
        message_template: "This was delivered in TestFlight build %<build_number>s",
        git_dir: tmpdir
      )
    end

    assert_equal("not authorized to get story 1234\n", stderr)

    assert_create_story_comment_not_requested(
      story_id: story_1_id,
    )

    assert_create_story_comment_requested(
      project_id: project_id,
      story_id: story_2_id,
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

  private def capture_stderr(&block)
    original_stderr = $stderr
    $stderr = fake = StringIO.new
    begin
      yield
    ensure
      $stderr = original_stderr
    end
    fake.string
  end

  private def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
  end
end
