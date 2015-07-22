defmodule MM do
  def benchmark(concurrency, num_requests, timeout, target) do
    :ok = :hackney_pool.start_pool(:benchmark, [
      max_connections: concurrency,
      timeout: timeout * 1000
    ])
    options = [pool: :benchmark, ssl_options: [verify_type: :verify_none]]

    results = 0..num_requests
    |> Enum.map(fn n ->
      Task.async(fn ->
        :timer.tc(&:hackney.get/4, [target, [], <<>>, options])
      end)
    end)
    |> Enum.with_index
    |> Enum.map(fn {task, index} ->
      result = Task.await(task, (10 + timeout) * 1000)
      IO.write("\r[#{index}/#{num_requests}] completed")
      result
    end)

    IO.puts ""
    results
  end
end
