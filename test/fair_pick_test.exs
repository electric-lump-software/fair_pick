defmodule FairPickTest do
  use ExUnit.Case, async: true

  describe "expand_pool/1" do
    test "sorts by id and expands weights" do
      entries = [
        %{id: "gamma", weight: 2},
        %{id: "alpha", weight: 3},
        %{id: "beta", weight: 1}
      ]

      assert FairPick.expand_pool(entries) ==
               ["alpha", "alpha", "alpha", "beta", "gamma", "gamma"]
    end

    test "weight 1 entries are not duplicated" do
      entries = [%{id: "b", weight: 1}, %{id: "a", weight: 1}]
      assert FairPick.expand_pool(entries) == ["a", "b"]
    end

    test "single entry" do
      entries = [%{id: "only", weight: 1}]
      assert FairPick.expand_pool(entries) == ["only"]
    end
  end

  describe "shuffle/2" do
    test "is deterministic — same seed produces same result" do
      pool = ["a", "b", "c", "d", "e"]
      seed = <<0::256>>
      {shuffled1, ctr1} = FairPick.shuffle(pool, seed)
      {shuffled2, ctr2} = FairPick.shuffle(pool, seed)
      assert shuffled1 == shuffled2
      assert ctr1 == ctr2
    end

    test "different seeds produce different results" do
      pool = ["a", "b", "c", "d", "e"]
      {shuffled1, _} = FairPick.shuffle(pool, <<0::256>>)
      {shuffled2, _} = FairPick.shuffle(pool, <<1::256>>)
      refute shuffled1 == shuffled2
    end

    test "preserves all elements" do
      pool = ["a", "b", "c"]
      seed = <<0::256>>
      {shuffled, _ctr} = FairPick.shuffle(pool, seed)
      assert Enum.sort(shuffled) == Enum.sort(pool)
    end

    test "single element pool is unchanged" do
      pool = ["only"]
      seed = <<0::256>>
      {shuffled, ctr} = FairPick.shuffle(pool, seed)
      assert shuffled == ["only"]
      # No random numbers consumed for single-element pool
      assert ctr == 0
    end

    test "returns final PRNG counter" do
      # Pool of 3 elements: shuffle iterates i=2 downto 1 = 2 random ints
      # (assuming no rejection sampling). Counter should be 2.
      pool = ["a", "b", "c"]
      seed = <<0::256>>
      {_shuffled, ctr} = FairPick.shuffle(pool, seed)
      assert ctr == 2
    end
  end

  describe "draw/3" do
    test "returns correct number of winners" do
      entries = [
        %{id: "a", weight: 1},
        %{id: "b", weight: 1},
        %{id: "c", weight: 1}
      ]

      seed = <<0::256>>
      result = FairPick.draw(entries, seed, 2)
      assert length(result) == 2
    end

    test "winners have 1-based positions" do
      entries = [%{id: "a", weight: 1}, %{id: "b", weight: 1}]
      seed = <<0::256>>
      result = FairPick.draw(entries, seed, 2)
      positions = Enum.map(result, & &1.position)
      assert positions == [1, 2]
    end

    test "deduplicates weighted entries" do
      entries = [%{id: "x", weight: 5}, %{id: "y", weight: 1}]
      seed = <<0::256>>
      result = FairPick.draw(entries, seed, 2)
      ids = Enum.map(result, & &1.entry_id)
      assert length(ids) == length(Enum.uniq(ids))
    end

    test "count exceeding unique entries returns all unique entries" do
      entries = [%{id: "solo", weight: 3}]
      seed = <<0::256>>
      result = FairPick.draw(entries, seed, 5)
      assert result == [%{position: 1, entry_id: "solo"}]
    end

    test "is deterministic" do
      entries = [
        %{id: "a", weight: 1},
        %{id: "b", weight: 1},
        %{id: "c", weight: 1}
      ]

      seed = <<42::256>>
      assert FairPick.draw(entries, seed, 2) == FairPick.draw(entries, seed, 2)
    end

    test "validates entries are non-empty" do
      assert_raise ArgumentError, fn ->
        FairPick.draw([], <<0::256>>, 1)
      end
    end

    test "validates no duplicate ids" do
      entries = [%{id: "a", weight: 1}, %{id: "a", weight: 2}]

      assert_raise ArgumentError, fn ->
        FairPick.draw(entries, <<0::256>>, 1)
      end
    end

    test "validates seed is 32 bytes" do
      entries = [%{id: "a", weight: 1}]

      assert_raise FunctionClauseError, fn ->
        FairPick.draw(entries, <<0::128>>, 1)
      end
    end
  end
end
