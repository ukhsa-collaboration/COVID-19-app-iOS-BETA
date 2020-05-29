require 'net/http'
require 'json'

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
    uri = URI("#{BASE_URL}/projects/#{project_id}/stories/#{story_id}/comments")
    body = JSON.dump({ text: text })
    Net::HTTP.post(uri, body, headers({ 'Content-Type' => 'application/json' }))
  end

  def deliver(project_id, story_id)
    uri = URI("#{BASE_URL}/projects/#{project_id}/stories/#{story_id}")
    body = JSON.dump({ current_state: :delivered })
    Net::HTTP.put(uri, body, headers({ 'Content-Type' => 'application/json' }))
  end

  def story(id)
    get("/stories/#{id}")
  end

  def me
    get("/me")
  end

  private
  def get(path)
    uri = URI("#{BASE_URL}#{path}")

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
