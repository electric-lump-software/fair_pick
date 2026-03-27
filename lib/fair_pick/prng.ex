defmodule FairPick.PRNG do
  @moduledoc false

  @doc """
  Generate a single 32-byte PRNG block.

  `block(seed, ctr) = SHA256(seed || BE32(ctr))`
  """
  @spec block(<<_::256>>, non_neg_integer()) :: <<_::256>>
  def block(<<seed::binary-size(32)>>, ctr) when is_integer(ctr) and ctr >= 0 do
    :crypto.hash(:sha256, <<seed::binary, ctr::32-big>>)
  end

  # Maximum value of a 256-bit unsigned integer + 1
  # 2^256
  @two_to_256 115_792_089_237_316_195_423_570_985_008_687_907_853_269_984_665_640_564_039_457_584_007_913_129_639_936

  @doc """
  Generate a uniform random integer in [0, n).

  Uses rejection sampling to eliminate modular bias.
  Returns `{value, next_counter}`.

  See README §Algorithm.
  """
  @spec random_integer(<<_::256>>, non_neg_integer(), pos_integer()) ::
          {non_neg_integer(), non_neg_integer()}
  def random_integer(seed, ctr, n) when n > 0 do
    limit = div(@two_to_256, n) * n
    do_random_integer(seed, ctr, n, limit)
  end

  defp do_random_integer(seed, ctr, n, limit) do
    <<v::unsigned-big-integer-size(256)>> = block(seed, ctr)

    if v >= limit do
      do_random_integer(seed, ctr + 1, n, limit)
    else
      {rem(v, n), ctr + 1}
    end
  end
end
