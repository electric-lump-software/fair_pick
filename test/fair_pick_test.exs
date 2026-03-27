defmodule FairPickTest do
  use ExUnit.Case, async: true

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
