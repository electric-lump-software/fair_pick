defmodule VectorsTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Test vectors for the spec (§3.1).
  These values are the canonical outputs — if this test passes,
  the generated values are correct by definition (reference implementation).
  """

  describe "Algorithm vector A-1: minimal draw" do
    test "verify output" do
      entries = [%{id: "a", weight: 1}, %{id: "b", weight: 1}, %{id: "c", weight: 1}]
      seed = <<0::256>>
      result = FairPick.draw(entries, seed, 1)

      assert result == [%{position: 1, entry_id: "c"}]
    end
  end

  describe "Algorithm vector A-2: weighted entries" do
    test "verify output" do
      entries = [
        %{id: "alpha", weight: 3},
        %{id: "beta", weight: 1},
        %{id: "gamma", weight: 2}
      ]

      seed = Base.decode16!("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF")
      result = FairPick.draw(entries, seed, 2)

      assert result == [
               %{position: 1, entry_id: "gamma"},
               %{position: 2, entry_id: "alpha"}
             ]
    end
  end

  describe "Algorithm vector A-3: deduplication" do
    test "verify output" do
      entries = [%{id: "x", weight: 5}, %{id: "y", weight: 1}]

      seed =
        Base.decode16!("ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789")

      result = FairPick.draw(entries, seed, 2)

      assert result == [
               %{position: 1, entry_id: "x"},
               %{position: 2, entry_id: "y"}
             ]
    end
  end

  describe "Algorithm vector A-4: count exceeds unique entries" do
    test "verify output" do
      entries = [%{id: "solo", weight: 3}]
      seed = Base.decode16!(String.duplicate("11", 32))
      result = FairPick.draw(entries, seed, 5)

      assert result == [%{position: 1, entry_id: "solo"}]
    end
  end

  describe "Algorithm vector A-5: single entry" do
    test "verify output" do
      entries = [%{id: "only", weight: 1}]
      seed = Base.decode16!(String.duplicate("22", 32))
      result = FairPick.draw(entries, seed, 1)

      assert result == [%{position: 1, entry_id: "only"}]
    end
  end
end
