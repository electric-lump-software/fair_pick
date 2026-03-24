defmodule FairPick.PRNGTest do
  use ExUnit.Case, async: true

  alias FairPick.PRNG

  describe "block/2" do
    test "produces SHA256(seed || BE32(counter))" do
      seed = <<0::256>>
      # SHA256(32 zero bytes || <<0, 0, 0, 0>>)
      expected = :crypto.hash(:sha256, <<seed::binary, 0::32-big>>)
      assert PRNG.block(seed, 0) == expected
    end

    test "different counters produce different blocks" do
      seed = <<0::256>>
      refute PRNG.block(seed, 0) == PRNG.block(seed, 1)
    end

    test "counter is encoded as 32-bit big-endian" do
      seed = <<1::256>>
      counter = 256
      expected = :crypto.hash(:sha256, <<seed::binary, 0, 0, 1, 0>>)
      assert PRNG.block(seed, counter) == expected
    end
  end

  describe "random_integer/3" do
    test "returns value in [0, n) and updated counter" do
      seed = <<0::256>>
      {value, next_ctr} = PRNG.random_integer(seed, 0, 10)
      assert value >= 0 and value < 10
      assert next_ctr == 1
    end

    test "is deterministic — same inputs produce same output" do
      seed = <<42::256>>
      assert PRNG.random_integer(seed, 0, 100) == PRNG.random_integer(seed, 0, 100)
    end

    test "n = 1 always returns 0" do
      seed = <<99::256>>
      {value, _ctr} = PRNG.random_integer(seed, 0, 1)
      assert value == 0
    end

    test "uses rejection sampling — skips biased values" do
      # With n = 2, limit = floor(2^256 / 2) * 2 = 2^256.
      # No value can be >= 2^256 in a 256-bit integer, so no rejection
      # should occur. Counter advances by exactly 1.
      seed = <<0::256>>
      {_value, ctr} = PRNG.random_integer(seed, 0, 2)
      assert ctr == 1
    end
  end
end
