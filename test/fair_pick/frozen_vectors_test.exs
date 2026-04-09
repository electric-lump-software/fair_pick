defmodule FairPick.FrozenVectorsTest do
  @moduledoc """
  Frozen test vectors. If any of these fail, the algorithm has drifted.
  Do not update the expected values without a version bump and a conversation.

  Generated against fair_pick v0.2.0.

  Each vector is a hardcoded {seed_bytes, entries, winner_count} -> expected_winners
  assertion. Exact order matters — these are protocol commitments.

  See also: WallopCore.FrozenVectorsTest for the protocol-level vectors.
  """

  use ExUnit.Case, async: true

  @seed Base.decode16!(
          "A1B2C3D4E5F6A7B8C9D0E1F2A3B4C5D6A7B8C9D0E1F2A3B4C5D6A7B8C9D0E1F2"
        )
  @seed_zeros <<0::256>>
  @seed_ones :binary.copy(<<0xFF::size(8)>>, 32)

  describe "frozen vectors (v0.2.0)" do
    test "1a: basic draw — 3 equal-weight entries, 2 winners" do
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

    test "1b: basic draw — zeros seed" do
      entries = [
        %{id: "alice", weight: 1},
        %{id: "bob", weight: 1},
        %{id: "charlie", weight: 1}
      ]

      result = FairPick.draw(entries, @seed_zeros, 2)

      assert result == [
               %{position: 1, entry_id: "charlie"},
               %{position: 2, entry_id: "bob"}
             ]
    end

    test "1c: basic draw — ones seed" do
      entries = [
        %{id: "alice", weight: 1},
        %{id: "bob", weight: 1},
        %{id: "charlie", weight: 1}
      ]

      result = FairPick.draw(entries, @seed_ones, 2)

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

    test "8: max weight spread — 3 entries, 1 winner" do
      entries = [
        %{id: "heavy", weight: 100},
        %{id: "medium", weight: 10},
        %{id: "light", weight: 1}
      ]

      result = FairPick.draw(entries, @seed, 1)

      assert result == [
               %{position: 1, entry_id: "heavy"}
             ]
    end

    test "9: winner_count exceeds entries — returns all in deterministic order" do
      entries = [
        %{id: "alpha", weight: 1},
        %{id: "beta", weight: 1}
      ]

      result = FairPick.draw(entries, @seed, 5)

      assert result == [
               %{position: 1, entry_id: "beta"},
               %{position: 2, entry_id: "alpha"}
             ]
    end
  end
end
