defmodule Ash.Test.Reactor.BulkUpdateTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Ash.Test.Domain

  defmodule Post do
    @moduledoc false
    use Ash.Resource, data_layer: Ash.DataLayer.Ets, domain: Domain

    attributes do
      uuid_primary_key :id
      attribute :title, :string, allow_nil?: false, public?: true
      attribute :published_at, :datetime, allow_nil?: true, public?: true
    end

    actions do
      defaults [:read, create: :*]

      update :publish do
        change set_attribute(:published_at, &DateTime.utc_now/0)
      end
    end

    calculations do
      calculate :published?, :boolean, expr(published_at <= now())
    end
  end

  defmodule BulkUpdateReactor do
    @moduledoc false
    use Reactor, extensions: [Ash.Reactor]

    input :posts_to_publish

    bulk_update :publish_posts, Post, :publish do
      initial(input(:posts_to_publish))
    end
  end

  test "it can update a bunch of records all at once" do
    how_many = :rand.uniform(99) + :rand.uniform(99)

    posts =
      1..how_many
      |> Enum.map(&%{title: "Post number #{&1}", published_at: nil})
      |> Ash.bulk_create(Post, :create, return_records?: true)
      |> Map.fetch!(:records)

    assert {:ok, _} =
             Reactor.run(BulkUpdateReactor, %{posts_to_publish: posts}, %{}, async?: false)

    updated_posts = Ash.read!(Post, action: :read, load: [:published?])

    assert Enum.all?(updated_posts, & &1.published?)
    assert length(updated_posts) == how_many
  end
end
