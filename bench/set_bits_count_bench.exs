import Bitwise

defmodule Bench.Popcount do
  import Bitwise

  # Current implementation
  def current(int) when is_integer(int) do
    do_current(int, 0)
  end

  defp do_current(0, acc), do: acc
  defp do_current(int, acc) do
    do_current(int >>> 1, acc + (int &&& 1))
  end
  
  # Proposed Implementation (Table 8-bit Unrolled)
  @popcount_table (for i <- 0..255, do: for(<<b::1 <- <<i::8>> >>, b == 1, reduce: 0, do: (acc -> acc + 1))) |> List.to_tuple()
  
  def table_8_unrolled(int) do
    elem(@popcount_table, int &&& 255) +
    elem(@popcount_table, (int >>> 8) &&& 255) +
    elem(@popcount_table, (int >>> 16) &&& 255) +
    elem(@popcount_table, (int >>> 24) &&& 255) +
    elem(@popcount_table, (int >>> 32) &&& 255) +
    elem(@popcount_table, (int >>> 40) &&& 255) +
    elem(@popcount_table, (int >>> 48) &&& 255) +
    elem(@popcount_table, (int >>> 56) &&& 255)
  end
end

Benchee.run(
  %{
    "Current" => fn input -> Bench.Popcount.current(input) end,
    "Table 8-bit Unrolled" => fn input -> Bench.Popcount.table_8_unrolled(input) end
  },
  inputs: %{
    "Zero (0 bits)" => 0,
    "Sparse (1 bit high)" => 1 <<< 62,
    "Dense (All 64 bits)" => (1 <<< 64) - 1,
    "Mixed" => 0xAAAAAAAAAAAAAAAA
  },
  time: 2,
  memory_time: 1
)