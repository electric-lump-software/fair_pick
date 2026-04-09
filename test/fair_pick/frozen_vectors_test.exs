defmodule FairPick.FrozenVectorsTest do
  @moduledoc """
  Frozen test vectors. If any of these fail, the algorithm has drifted.
  Do not update the expected values without a version bump and a conversation.

  Generated against fair_pick v0.2.0.

  Each vector is a hardcoded {seed_bytes, entries, winner_count} -> expected_winners
  assertion. Exact order matters — these are protocol commitments.
  """

  use ExUnit.Case, async: true

  @seed Base.decode16!(
          "A1B2C3D4E5F6A7B8C9D0E1F2A3B4C5D6A7B8C9D0E1F2A3B4C5D6A7B8C9D0E1F2"
        )

  describe "frozen vectors (v0.2.0)" do
    test "1: basic draw — 3 equal-weight entries, 2 winners" do
      entries = [
        %{id: "alice", weight: 1},
        %{id: "bob", weight: 1},
        %{id: "charlie", weight: 1}
      ]

      result = FairPick.draw(entries, @seed, 2)

      assert result == [
               %{position: 1, entry_id: "bob"},
               %{position: 2, entry_id: "charlie"}
             ]
    end

    test "2: weighted draw — different weights affect selection" do
      entries = [
        %{id: "alice", weight: 10},
        %{id: "bob", weight: 1},
        %{id: "charlie", weight: 5}
      ]

      result = FairPick.draw(entries, @seed, 2)

      assert result == [
               %{position: 1, entry_id: "alice"},
               %{position: 2, entry_id: "charlie"}
             ]
    end

    test "3: single winner" do
      entries = [
        %{id: "alice", weight: 1},
        %{id: "bob", weight: 1},
        %{id: "charlie", weight: 1}
      ]

      result = FairPick.draw(entries, @seed, 1)

      assert result == [
               %{position: 1, entry_id: "bob"}
             ]
    end

    test "4: all winners — deterministic full ordering" do
      entries = [
        %{id: "alice", weight: 1},
        %{id: "bob", weight: 1},
        %{id: "charlie", weight: 1},
        %{id: "dave", weight: 1}
      ]

      result = FairPick.draw(entries, @seed, 4)

      assert result == [
               %{position: 1, entry_id: "dave"},
               %{position: 2, entry_id: "charlie"},
               %{position: 3, entry_id: "bob"},
               %{position: 4, entry_id: "alice"}
             ]
    end

    test "5: single entry — degenerate case" do
      entries = [%{id: "solo", weight: 1}]

      result = FairPick.draw(entries, @seed, 1)

      assert result == [
               %{position: 1, entry_id: "solo"}
             ]
    end

    test "6: large entry set — 100 entries, 5 winners" do
      entries =
        Enum.map(1..100, fn i ->
          %{id: "entry_#{String.pad_leading(Integer.to_string(i), 3, "0")}", weight: 1}
        end)

      result = FairPick.draw(entries, @seed, 5)

      assert result == [
               %{position: 1, entry_id: "entry_062"},
               %{position: 2, entry_id: "entry_038"},
               %{position: 3, entry_id: "entry_023"},
               %{position: 4, entry_id: "entry_044"},
               %{position: 5, entry_id: "entry_065"}
             ]
    end

    test "7: duplicate weights — all same weight, stable tiebreaking" do
      entries = [
        %{id: "alpha", weight: 3},
        %{id: "beta", weight: 3},
        %{id: "gamma", weight: 3},
        %{id: "delta", weight: 3},
        %{id: "epsilon", weight: 3}
      ]

      result = FairPick.draw(entries, @seed, 3)

      assert result == [
               %{position: 1, entry_id: "alpha"},
               %{position: 2, entry_id: "beta"},
               %{position: 3, entry_id: "epsilon"}
             ]
    end

    test "8: max weight spread — weight 1 vs weight 1000" do
      entries = [
        %{id: "heavy", weight: 1000},
        %{id: "light", weight: 1}
      ]

      result = FairPick.draw(entries, @seed, 2)

      assert result == [
               %{position: 1, entry_id: "heavy"},
               %{position: 2, entry_id: "light"}
             ]
    end
  end
end
