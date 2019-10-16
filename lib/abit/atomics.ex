defmodule Abit.Atomics do
  @moduledoc false

  def to_list(atomics_ref) when is_reference(atomics_ref) do
    do_to_list(atomics_ref, 1, :atomics.info(atomics_ref).size)
  end

  defp do_to_list(atomics_ref, size, size) do
    [:atomics.get(atomics_ref, size)]
  end

  defp do_to_list(atomics_ref, index, size) do
    [:atomics.get(atomics_ref, index) | do_to_list(atomics_ref, index + 1, size)]
  end

  def member?(atomics_ref, int) when is_reference(atomics_ref) and is_integer(int) do
    %{min: min, max: max, size: size} = :atomics.info(atomics_ref)

    case int do
      i when i < min ->
        false

      i when i > max ->
        false

      _else ->
        do_member?(atomics_ref, int, size, false)
    end
  end

  defp do_member?(_, _, _, true), do: true

  defp do_member?(_, _, 0, false), do: false

  defp do_member?(atomics_ref, int, index, false) do
    do_member?(
      atomics_ref,
      int,
      index - 1,
      :atomics.get(atomics_ref, index) == int
    )
  end
end
