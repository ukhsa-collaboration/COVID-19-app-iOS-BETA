require 'open3'

module Git
  module_function
  def git_logs(git_dir, rev_list)
    out, err, status = Open3.capture3(*%W(
      git -C #{git_dir} log --format='%B' #{rev_list}
    ))
    raise "Command failed: \n\n#{err}" if status.exitstatus !=0
    out
  end
end
