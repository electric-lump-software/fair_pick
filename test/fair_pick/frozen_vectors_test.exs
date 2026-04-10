defmodule FairPick.FrozenVectorsTest do
  @moduledoc """
  Frozen test vectors loaded from the shared wallop spec.

  These are the canonical outputs — if any of these fail, the algorithm has
  drifted from the cross-implementation contract. Do not update the expected
  values without a version bump and a conversation.

  Source: ../wallop/spec/vectors/fair-pick.json

  If the wallop repo is not checked out as a sibling, these tests are skipped
  (not a compilation error).
  """

  use ExUnit.Case, async: true

  @vectors_path Path.expand("../../../wallop/spec/vectors/fair-pick.json", __DIR__)

  @vectors (case File.read(@vectors_path) do
              {:ok, json} -> Jason.decode!(json) |> Map.fetch!("vectors")
              {:error, _} -> nil
            end)

  if @vectors do
    for {vector, index} <- Enum.with_index(@vectors) do
      @vector vector
      @tag_name "shared vector #{index + 1}: #{vector["name"]}"

      describe @tag_name do
        test "matches expected winners" do
          vector = @vector

          entries =
            Enum.map(vector["entries"], fn e ->
              %{id: e["id"], weight: e["weight"]}
            end)

          seed =
            case vector do
              %{"seed_hex" => hex} ->
                Base.decode16!(hex, case: :lower)

              %{"seed_note" => note} ->
                case Regex.run(~r/^SHA-256\("(.+)"\)$/, note) do
                  [_, inner] -> :crypto.hash(:sha256, inner)
                  nil -> flunk("Unrecognised seed_note format: #{note}")
                end
            end

          winner_count = vector["winner_count"]

          result = FairPick.draw(entries, seed, winner_count)
          actual_winners = Enum.map(result, & &1.entry_id)

          assert actual_winners == vector["expected_winners"],
                 "Vector '#{vector["name"]}' failed.\nExpected: #{inspect(vector["expected_winners"])}\nGot: #{inspect(actual_winners)}"
        end
      end
    end
  else
    @moduletag :skip
    IO.warn("Skipping shared frozen vectors — wallop repo not found at #{@vectors_path}")
  end
end
