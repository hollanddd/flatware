module ProcessSupport
  def child_pids(pid=Process.pid)
    `ps -o ppid -o pid`.split("\n")[1..-1].map do |l|
      l.split.map(&:to_i)
    end.inject(Hash.new([])) do |h, (ppid, pid)|
    h.tap { h[ppid] += [pid] }
    end[pid]
  end
end
