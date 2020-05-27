require 'tmpdir'
require 'stringio'

require 'test_support/git_test_support'
require 'test_support/tracker_webmock_support'
require 'test_support/output_capture_support'

require 'generates_release_notes'

class TestGeneratesReleaseNotes < MiniTest::Test
  include GitTestSupport
  include TrackerWebmockSupport
  include OutputCaptureSupport
  include GeneratesReleaseNotes

  attr_accessor :tracker_token
  attr_accessor :tmpdir
  attr_accessor :stub_headers
  attr_accessor :io

  def setup
    @tmpdir = Dir.mktmpdir
    @tracker_token = 'tracker_token'
    @io = StringIO.new

    @stub_headers = {
      'Accept' => 'application/json',
      'X-TrackerToken' => tracker_token,
      'User-Agent' => /.*/,
      'Accept-Encoding' => /.*/,
    }

    git_init(tmpdir)
    git_empty_commit('first commit')

    stub_all_tracker_requests
    stub_me_request_200
  end

  def test_fails_when_not_authenticated
    story_id = 1234
    git_empty_commit("[Finishes ##{story_id}] a commit")

    stub_me_request_401

    assert_raises(RuntimeError, 'unable to authenticate with pivotal tracker') do
      generate_release_notes(
        io: io,
        tracker_token: tracker_token,
        commits: 'HEAD',
        git_dir: tmpdir
      )
    end
  end

  def test_returns_empty_output_for_no_finished_stories
    generate_release_notes(
      io: io,
      tracker_token: tracker_token,
      commits: 'HEAD',
      git_dir: tmpdir
    )
    assert_equal("No changes\n", release_notes)
  end

  def test_returns_a_list_of_changes_with_links_to_tracker_stories_as_markdown
    project_id = 9876
    story_1_id = 1234

    story_2_id = 2345

    git_empty_commit("[Finishes ##{story_1_id}] a commit")
    git_empty_commit("[Finishes ##{story_2_id}] a commit")

    stub_get_story_request(
      project_id: project_id,
      story_id: story_1_id,
      name: "Story 1",
    )

    stub_get_story_request(
      project_id: project_id,
      story_id: story_2_id,
      name: "Story 2",
    )

    generate_release_notes(
      io: io,
      tracker_token: tracker_token,
      commits: 'HEAD~2..HEAD',
      git_dir: tmpdir
    )

    assert_equal(<<~EXPECTED, release_notes)
    Changes (HEAD~2..HEAD)

      * [##{story_2_id}](#{TRACKER_API}/story/show/#{story_2_id}) - Story 2
      * [##{story_1_id}](#{TRACKER_API}/story/show/#{story_1_id}) - Story 1
    EXPECTED
  end

  private

  def release_notes
    io.string
  end
end
