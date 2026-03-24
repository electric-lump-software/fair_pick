defmodule FairPick do
  @moduledoc """
  Deterministic, verifiable draw algorithm.

  Given a list of entries, a seed, and a winner count, produces an ordered
  list of winners. Same inputs always produce the same output.

  See docs/specs/fair-pick-protocol.md §1 for the full specification.
  """

  @doc """
  Sort entries by id and expand into a flat pool.

  Each entry with weight N produces N consecutive copies of its id.
  Entries are sorted by id in ascending lexicographic byte order first.
  """
  @spec expand_pool([%{id: String.t(), weight: pos_integer()}]) :: [String.t()]
  def expand_pool(entries) do
    entries
    |> Enum.sort_by(& &1.id)
    |> Enum.flat_map(fn %{id: id, weight: weight} ->
      List.duplicate(id, weight)
    end)
  end

  @doc """
  Durstenfeld (modern Fisher-Yates) shuffle.

  Performs the FULL shuffle regardless of how many winners are needed.
  Returns `{shuffled_list, final_prng_counter}`.

  See docs/specs/fair-pick-protocol.md §1.5.
  """
  @spec shuffle([String.t()], <<_::256>>) :: {[String.t()], non_neg_integer()}
  def shuffle(pool, _seed) when length(pool) <= 1 do
    {pool, 0}
  end

  def shuffle(pool, seed) do
    arr = :array.from_list(pool)
    m = :array.size(arr)

    {arr, ctr} =
      Enum.reduce((m - 1)..1//-1, {arr, 0}, fn i, {acc, ctr} ->
        {j, next_ctr} = FairPick.PRNG.random_integer(seed, ctr, i + 1)

        val_i = :array.get(i, acc)
        val_j = :array.get(j, acc)

        acc = :array.set(i, val_j, acc)
        acc = :array.set(j, val_i, acc)

        {acc, next_ctr}
      end)

    {:array.to_list(arr), ctr}
  end

  @doc """
  Run a deterministic draw.

  Returns an ordered list of `%{position: pos, entry_id: id}` maps.
  Same inputs always produce the same output.

  See docs/specs/fair-pick-protocol.md §1 for the full specification.
  """
  @spec draw([%{id: String.t(), weight: pos_integer()}], <<_::256>>, pos_integer()) ::
          [%{position: pos_integer(), entry_id: String.t()}]
  def draw(entries, <<_seed::binary-size(32)>> = seed, count)
      when is_list(entries) and is_integer(count) and count > 0 do
    validate_entries!(entries)

    pool = expand_pool(entries)
    {shuffled, _ctr} = shuffle(pool, seed)

    shuffled
    |> Enum.reduce({[], MapSet.new()}, fn id, {winners, seen} ->
      if MapSet.member?(seen, id) do
        {winners, seen}
      else
        {[id | winners], MapSet.put(seen, id)}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
    |> Enum.take(count)
    |> Enum.with_index(1)
    |> Enum.map(fn {id, pos} -> %{position: pos, entry_id: id} end)
  end

  defp validate_entries!([]) do
    raise ArgumentError, "entries must not be empty"
  end

  defp validate_entries!(entries) do
    ids = Enum.map(entries, & &1.id)

    if length(ids) != length(Enum.uniq(ids)) do
      raise ArgumentError, "entries must not contain duplicate ids"
    end

    :ok
  end
end
