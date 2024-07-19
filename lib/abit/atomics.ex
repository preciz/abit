defmodule Abit.Atomics do
  @moduledoc """
  Internal module for working with Erlang's :atomics.

  This module provides utility functions for working with Erlang's :atomics.
  It should not be used directly by users of the Abit library.
  """

  @doc """
  Converts an :atomics reference to a list of integers.

  This function takes an :atomics reference and returns a list of integers,
  where each integer represents the value stored in each atomic.

  ## Parameters

    * `atomics_ref` - A reference to an :atomics array.

  ## Returns

  A list of integers representing the values stored in the :atomics array.

  ## Examples

      iex> ref = :atomics.new(3, signed: false)
      iex> :atomics.put(ref, 1, 10)
      iex> :atomics.put(ref, 2, 20)
      iex> :atomics.put(ref, 3, 30)
      iex> Abit.Atomics.to_list(ref)
      [10, 20, 30]

  """
  def to_list(atomics_ref) when is_reference(atomics_ref) do
    do_to_list(atomics_ref, 1, :atomics.info(atomics_ref).size)
  end

  defp do_to_list(atomics_ref, size, size) do
    [:atomics.get(atomics_ref, size)]
  end

  defp do_to_list(atomics_ref, index, size) do
    [:atomics.get(atomics_ref, index) | do_to_list(atomics_ref, index + 1, size)]
  end

  @doc """
  Checks if an integer is present in the :atomics reference.

  This function checks if the given integer exists as a value in any of the
  atomics within the provided :atomics reference.

  ## Parameters

    * `atomics_ref` - A reference to an :atomics array.
    * `int` - The integer to search for.

  ## Returns

  Returns `true` if the integer is found in the :atomics array, `false` otherwise.

  ## Examples

      iex> ref = :atomics.new(3, signed: false)
      iex> :atomics.put(ref, 1, 10)
      iex> :atomics.put(ref, 2, 20)
      iex> :atomics.put(ref, 3, 30)
      iex> Abit.Atomics.member?(ref, 20)
      true
      iex> Abit.Atomics.member?(ref, 40)
      false

  """
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
