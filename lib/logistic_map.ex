defmodule LogisticMap do

  @logistic_map_size      0x2000000
  @default_prime 6_700_417
  @default_mu 22
  @default_loop 10

  @moduledoc """
  Documentation for LogisticMap.
  """

  @doc """
  calc logistic map.

  ## Examples

      iex> LogisticMap.calc(1, 61, 22)
      44

  """
  def calc(x, p, mu) do
    rem(mu * x * (x + 1), p)
  end

  @doc """
  loop logistic map

  ## Examples

      iex> LogisticMap.loopCalc(10, 1, 61, 22)
      28

  """
  def loopCalc(num, x, p, mu) do
    if num <= 0 do
      x
    else
      loopCalc(num - 1, calc(x, p, mu), p, mu)
    end
  end

  @doc """
  loop logistic map

  ## Examples

      iex> LogisticMap.loopCalc2(10, 1, 61, 22)
      28

  """
  def loopCalc2(num, x, _p, _mu) when num <= 0 do x end
  def loopCalc2(num, x, p, mu) do
    new_num = num - 1
    new_calc = calc( x, p, mu )
    loopCalc2( new_num, new_calc, p, mu )
  end


  @doc """
  Flow.map calc logictic map

  ## Examples

      iex> 1..3 |> LogisticMap.mapCalc(10, 61, 22, 1)
      [28, 25, 37]

  """
  def mapCalc(list, num, p, mu, stages) do
    list
    |> Flow.from_enumerable(stages: stages)
    |> Flow.map(& loopCalc(num, &1, p, mu))
    |> Enum.to_list
  end

  @doc """
  Flow.map calc logictic map

  ## Examples

      iex> 1..3 |> LogisticMap.mapCalc2(61, 22, 1)
      [28, 25, 37]

  """
  def mapCalc2(list, p, mu, stages) do
    list
    |> Flow.from_enumerable(stages: stages)
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Enum.to_list
  end

  @doc """
  Flow.map calc logictic map

  ## Examples

      iex> 1..3 |> LogisticMap.mapCalc3(61, 22, 1)
      [28, 25, 37]

  """
  def mapCalc3(list, p, mu, stages) do
    list
    |> Flow.from_enumerable(stages: stages)
    |> Flow.map(& (&1
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      ))
    |> Enum.to_list
  end


  @doc """
  Flow.map calc logictic map

  ## Examples

      iex> 1..3 |> LogisticMap.mapCalc4(10, 61, 22, 1)
      [28, 25, 37]

  """
  def mapCalc4(list, num, p, mu, stages) do
    list
    |> Flow.from_enumerable(stages: stages)
    |> Flow.map(& loopCalc2(num, &1, p, mu))
    |> Enum.to_list
  end

  @doc """
  Benchmark
  """
  def benchmark1(stages) do
    IO.puts "stages: #{stages}"
    IO.puts (
      :timer.tc(fn -> mapCalc(1..@logistic_map_size, @default_loop, @default_prime, @default_mu, stages) end)
      |> elem(0)
      |> Kernel./(1000000)
    )
  end

  @doc """
  Benchmark
  """
  def benchmark2(stages) do
    IO.puts "stages: #{stages}"
    IO.puts (
      :timer.tc(fn -> LogisticMap.mapCalc2(1..@logistic_map_size, @default_prime, @default_mu, stages) end)
      |> elem(0)
      |> Kernel./(1000000)
    )
  end


  @doc """
  Benchmark
  """
  def benchmark3(stages) do
    IO.puts "stages: #{stages}"
    IO.puts (
      :timer.tc(fn -> LogisticMap.mapCalc3(1..@logistic_map_size, @default_prime, @default_mu, stages) end)
      |> elem(0)
      |> Kernel./(1000000)
    )
  end


  @doc """
  Benchmark
  """
  def benchmark4(stages) do
    IO.puts "stages: #{stages}"
    IO.puts (
      :timer.tc(fn -> mapCalc4(1..@logistic_map_size, @default_loop, @default_prime, @default_mu, stages) end)
      |> elem(0)
      |> Kernel./(1000000)
    )
  end

  @doc """
  Benchmarks
  """
  def benchmarks1() do
    [1, 2, 4, 8, 16, 32, 64, 128]
    |> Enum.map(& benchmark1(&1))
    |> Enum.reduce(0, fn _lst, acc -> acc end)
  end

  @doc """
  Benchmarks
  """
  def benchmarks2() do
    [1, 2, 4, 8, 16, 32, 64, 128]
    |> Enum.map(& benchmark2(&1))
    |> Enum.reduce(0, fn _lst, acc -> acc end)
  end


  @doc """
  Benchmarks
  """
  def benchmarks3() do
    [1, 2, 4, 8, 16, 32, 64, 128]
    |> Enum.map(& benchmark3(&1))
    |> Enum.reduce(0, fn _lst, acc -> acc end)
  end

  @doc """
  Benchmarks
  """
  def benchmarks4() do
    [1, 2, 4, 8, 16, 32, 64, 128]
    |> Enum.map(& benchmark4(&1))
    |> Enum.reduce(0, fn _lst, acc -> acc end)
  end

  def allbenchmarks() do
    [
     {&benchmarks1/0, "benchmarks1: pure Elixir(loop)"},
     # {&benchmarks2/0, "benchmarks2: pure Elixir(inlining outside of Flow.map)"},
     {&benchmarks3/0, "benchmarks3: pure Elixir(inlining inside of Flow.map)"},
     # {&benchmarks4/0, "benchmarks4: pure Elixir(loop: variation)"},
     # {&benchmarks5/0, "benchmarks5: Rustler loop, passing by list"},
     # {&benchmarks6/0, "benchmarks6: Rustler loop, passing by binary created by Elixir"},
     # {&benchmarks7/0, "benchmarks7: Rustler loop, passing by binary created by Rustler"},
     # {&benchmarks8/0, "benchmarks8: Rustler loop, passing by list, with Window"},
     # {&benchmarks_g1/0, "benchmarks_g1: OpenCL(GPU)"},
     # {&benchmarks_g2/0, "benchmarks_g2: OpenCL(GPU) asynchronously"},
     # {&benchmarks_empty/0, "benchmarks_empty: Ruslter empty"},
     # {&benchmarks_t1/0, "benchmarks_t1: asynchronous multi-threaded Rustler, passing by list"}
    ]
    |> Enum.map(fn (x) ->
      IO.puts elem(x, 1)
      elem(x, 0).()
    end)
  end
end
