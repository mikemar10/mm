defmodule MM do
  def benchmark(concurrency, num_requests, timeout, target) do
    setup_pool(concurrency, timeout)
    initiate_requests(num_requests, target) 
    |> collect_results(timeout)
  end

  def setup_pool(concurrency, timeout) do
    :ok = :hackney_pool.start_pool(:benchmark, [
      max_connections: concurrency,
      timeout: timeout * 1000
    ])
  end

  def initiate_requests(num_requests, target) do
    options = [pool: :benchmark, ssl_options: [verify_type: :verify_none]]
    0..num_requests
    |> Enum.map(fn n ->
      Task.async(fn ->
        { time, results } = :timer.tc(&:hackney.get/4, [target, [], <<>>, options])
        case results do
          {:ok, status, _headers, _client} -> {time, {:ok, status, nil, nil}}
          results -> {time, results}
        end
      end)
    end)
  end

  def collect_results(requests, timeout) do
    requests
    |> Enum.map(fn task ->
      Task.await(task, (10 + timeout) * 1000)
    end)
  end
end
