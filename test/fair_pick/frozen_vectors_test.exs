defmodule FairPick.FrozenVectorsTest do
  @moduledoc """
  Frozen test vectors loaded from the shared wallop spec.

  These are the canonical outputs — if any of these fail, the algorithm has
  drifted from the cross-implementation contract. Do not update the expected
  values without a version bump and a conversation.

  Source: vendor/wallop/spec/vectors/fair-pick.json

  If the wallop submodule has not been initialised, these tests are skipped
  (not a compilation error). Run `git submodule update --init` to fetch it.
  """

  use ExUnit.Case, async: true

  @vectors_path Path.expand("../../vendor/wallop/spec/vectors/fair-pick.json", __DIR__)

  @vectors (case File.read(@vectors_path) do
              {:ok, json} -> Jason.decode!(json) |> Map.fetch!("vectors")
              {:error, _} -> nil
            end)

  if @vectors do
    for {vector, index} <- Enum.with_index(@vectors) do
      @vector vector
      @tag_name "shared vector #{index + 1}: #{vector["name"]}"

      describe @tag_name do
        test "seed_hex matches SHA-256(seed_note) when both present" do
          vector = @vector

          case vector do
            %{"seed_hex" => hex, "seed_note" => note} ->
              [_, inner] = Regex.run(~r/^SHA-256\("(.+)"\)$/, note)
              expected_hex = :crypto.hash(:sha256, inner) |> Base.encode16(case: :lower)

              assert hex == expected_hex,
                     "seed_hex does not match SHA-256(seed_note) for '#{vector["name"]}'"

            _ ->
              :ok
          end
        end

        test "matches expected winners" do
          vector = @vector

          entries =
            Enum.map(vector["entries"], fn e ->
              %{id: e["id"], weight: e["weight"]}
            end)

          seed = Base.decode16!(vector["seed_hex"], case: :lower)
          winner_count = vector["winner_count"]

          result = FairPick.draw(entries, seed, winner_count)
          actual_winners = Enum.map(result, & &1.entry_id)

          assert actual_winners == vector["expected_winners"],
                 "Vector '#{vector["name"]}' failed.\nExpected: #{inspect(vector["expected_winners"])}\nGot: #{inspect(actual_winners)}"
        end
      end
    end
  else
    if System.get_env("WALLOP_REQUIRE_SHARED_VECTORS") == "1" do
      raise "Shared vectors required but not found at #{@vectors_path}. Run: git submodule update --init"
    end

    @moduletag :skip
    IO.warn(
      "Skipping shared frozen vectors — wallop submodule not found at #{@vectors_path}. " <>
        "Run: git submodule update --init"
    )
  end
end
