require 'webmock/minitest'

module TrackerWebmockSupport
  include WebMock::Matchers

  TRACKER_API = 'https://www.pivotaltracker.com/services/v5'
  private_constant :TRACKER_API

  module_function

  def stub_all_tracker_requests
    stub_request(:any, %r{https://www.pivotaltracker.com.*})
  end

  def assert_no_tracker_requests
    assert_not_requested(:any, %r{https://www.pivotaltracker.com.*})
  end

  def assert_create_story_comment_requested(
    project_id:,
    story_id:,
    message:,
    times: 1
  )
    assert_requested(
      :post,
      "#{TRACKER_API}/projects/#{project_id}/stories/#{story_id}/comments",
      headers: stub_headers,
      body: {
        :text => message
      }.to_json,
      times: times
    )
  end

  def assert_get_story_request(
    story_id:,
    times: 1
  )
    assert_requested(
      :get,
      "#{TRACKER_API}/stories/#{story_id}",
      headers: stub_headers
    )
  end

  def assert_create_story_comment_not_requested(story_id:)
    assert_not_requested(
      :post,
      %r{#{TRACKER_API}/projects/\d+/stories/#{story_id}/comments},
      headers: stub_headers
    )
  end

  def _stub_me_request
    stub_request(
      :get,
      "#{TRACKER_API}/me"
    ).with(
      headers: stub_headers
    )
  end

  def stub_me_request_200
    _stub_me_request.to_return(
      status: 200,
    )
  end

  def stub_me_request_401
    _stub_me_request.to_return(
      status: 401,
    )
  end

  def stub_get_story_request(
    project_id:,
    story_id:
  )
    _stub_get_story_request(story_id).to_return(
      status: 200,
      body: { :project_id => project_id }.to_json
    )
  end

  def stub_get_story_request_404(
    story_id:
  )
    _stub_get_story_request(story_id).to_return(
      status: 404,
    )
  end

  def stub_get_story_request_403(
    story_id:
  )
    _stub_get_story_request(story_id).to_return(
      status: 403,
    )
  end

  def _stub_get_story_request(story_id)
    stub_request(
      :get,
      "#{TRACKER_API}/stories/#{story_id}"
    ).with(
      headers: stub_headers
    )
  end
end
