module GitTestSupport
  module_function

  def git_init(dir)
    system('git', 'init', dir)
  end

  def git_empty_commit(message)
    system(
      'git', '-C', tmpdir, 'commit',
      '--allow-empty',
      '--message', message
    )
  end
end
