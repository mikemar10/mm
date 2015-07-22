defmodule MM.CLI do
  @default_concurrency 20
  @default_number_of_requests 100
  @default_timeout 15

  def main(args) do
    args
    |> parse_args
    |> process
    |> summarize
  end

  defp parse_args(args) do
    OptionParser.parse(args, 
      strict: [
        concurrent:  :integer,
        number:      :integer,
        help:        :boolean,
        timeout:     :integer
      ],
      aliases: [
        c: :concurrent,
        n: :number,
        h: :help,
        t: :timeout
      ])
  end
  
  defp process({parsed, [url], _}) do
    concurrency = Keyword.get(parsed, :concurrent, @default_concurrency)
    number      = Keyword.get(parsed, :number, @default_number_of_requests)
    timeout     = Keyword.get(parsed, :timeout, @default_timeout)
    help        = Keyword.get(parsed, :help)

    if help, do: process(:true)
    MM.benchmark(concurrency, number, timeout, url) 
  end

  defp process(:help) do
    IO.puts """
    usage: mm [[--concurrent|-c] #] [[--number|-n] #] [[--timeout|-t] #] [--help|-h] url
    
    concurrent: Number of concurrent requests, default #{@default_concurrency}
    number:     Total number of requests, default #{@default_number_of_requests}
    help:       Displays this help message
    timeout:    Sets the request timeout in seconds #{@default_timeout}
    url:        Target URL to benchmark
    """
    System.halt(0)
  end

  defp process(_) do
    process(:help)
  end

  defp summarize(results) do
    results
    |> fastest_response
    |> slowest_response
    |> average_response
    |> standard_deviation
    |> status_codes
  end

  defp fastest_response(results) do
    fastest = results
              |> Enum.map(fn {time, _} -> time end)
              |> Enum.min
              |> to_seconds
    IO.puts("Fastest response: #{fastest} seconds")
    results
  end

  defp slowest_response(results) do
    slowest = results
              |> Enum.map(fn {time, _} -> time end)
              |> Enum.max
              |> to_seconds
    IO.puts("Slowest response: #{slowest} seconds")
    results
  end

  defp average_response(results) do
    average = results
              |> Enum.map(fn {time, _} -> time end)
              |> Enum.reduce(0, fn t, acc -> acc + t end)
              |> to_seconds
    IO.puts("Average response: #{average / length(results)} seconds")
    results
  end

  defp status_codes(results) do
    IO.puts "HTTP STATUSES"
    statuses = results
               |> Enum.reduce(Map.new, fn {_, result}, map ->
                 case result do
                   {:ok, status, _, _} -> Map.update(map, status, 0, &(&1 + 1))
                   {:error, reason}    -> Map.update(map, reason, 0, &(&1 + 1))
                 end
               end)
               |> Enum.each(fn {k,v} -> IO.puts "#{k}: #{v}" end)
    results
  end

  defp standard_deviation(results) do
    times = Enum.map(results, fn {time, _} -> time end)
    average = :lists.sum(times) / length(times)
    deviations = Enum.map(times, fn t -> :math.pow(t - average, 2) end)
    stdev = :math.sqrt(:lists.sum(deviations) / length(deviations)) |> to_seconds
    IO.puts("Standard Deviation: #{stdev} seconds")
    results
  end

  defp to_seconds(microseconds) do
    microseconds / 1_000_000
  end
end
