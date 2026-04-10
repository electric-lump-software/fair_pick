defmodule FairPick.FrozenVectorsTest do
  @moduledoc """
  Frozen test vectors loaded from the shared wallop spec.

  These are the canonical outputs — if any of these fail, the algorithm has
  drifted from the cross-implementation contract. Do not update the expected
  values without a version bump and a conversation.

  Source: ../wallop/spec/vectors/fair-pick.json
  """

  use ExUnit.Case, async: true

  @vectors_path Path.expand("../../../wallop/spec/vectors/fair-pick.json", __DIR__)

  @vectors (
    case File.read(@vectors_path) do
      {:ok, json} ->
        Jason.decode!(json) |> Map.fetch!("vectors")

      {:error, _} ->
        raise """
        Shared test vectors not found at #{@vectors_path}.
        Make sure the wallop repo is checked out at ../wallop.
        """
    end
  )

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
              # seed_note is like: SHA-256("frozen-equal-weight-vector")
              inner = note |> String.trim_leading("SHA-256(\"") |> String.trim_trailing("\")")
              :crypto.hash(:sha256, inner)
          end

        winner_count = vector["winner_count"]

        result = FairPick.draw(entries, seed, winner_count)
        actual_winners = Enum.map(result, & &1.entry_id)

        assert actual_winners == vector["expected_winners"],
               "Vector '#{vector["name"]}' failed.\nExpected: #{inspect(vector["expected_winners"])}\nGot: #{inspect(actual_winners)}"
      end
    end
  end
end
