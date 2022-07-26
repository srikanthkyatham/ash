defmodule Ash.Resource.Attribute do
  @moduledoc "Represents an attribute on a resource"

  defstruct [
    :name,
    :type,
    :allow_nil?,
    :generated?,
    :primary_key?,
    :private?,
    :writable?,
    :always_select?,
    :default,
    :update_default,
    :description,
    :source,
    match_other_defaults?: false,
    sensitive?: false,
    filterable?: true,
    constraints: []
  ]

  @type t :: %__MODULE__{
          name: atom(),
          constraints: Keyword.t(),
          type: Ash.Type.t(),
          primary_key?: boolean(),
          private?: boolean(),
          default: (() -> term),
          update_default: (() -> term) | (Ash.Resource.record() -> term),
          sensitive?: boolean(),
          writable?: boolean()
        }

  alias Ash.OptionsHelpers

  @schema [
    name: [
      type: :atom,
      doc: "The name of the attribute.",
      links: []
    ],
    type: [
      type: :ash_type,
      doc: "The type of the attribute.",
      links: [
        modules: ["ash:module:Ash.Type"]
      ]
    ],
    constraints: [
      type: :keyword_list,
      doc:
        "Constraints to provide to the type when casting the value. See the type's documentation for more information.",
      links: [
        modules: ["ash:module:Ash.Type"]
      ]
    ],
    sensitive?: [
      type: :boolean,
      default: false,
      doc:
        "Whether or not the attribute value contains sensitive information, like PII. If so, it will be redacted while inspecting data.",
      links: [
        guides: ["ash:guide:Security"]
      ]
    ],
    source: [
      type: :atom,
      doc: """
      If the field should be mapped to a different name in the data layer.
      """
    ],
    always_select?: [
      type: :boolean,
      default: false,
      doc: """
      Whether or not to ensure this attribute is always selected when reading from the database.
      """
    ],
    primary_key?: [
      type: :boolean,
      default: false,
      doc: """
      Whether or not the attribute is part of the primary key (one or more fields that uniquely identify a resource)."
      If primary_key? is true, allow_nil? must be false.
      """
    ],
    allow_nil?: [
      type: :boolean,
      default: true,
      doc: "Whether or not the attribute can be set to nil."
    ],
    generated?: [
      type: :boolean,
      default: false,
      doc: "Whether or not the value may be generated by the data layer."
    ],
    writable?: [
      type: :boolean,
      default: true,
      doc: "Whether or not the value can be written to."
    ],
    private?: [
      type: :boolean,
      default: false,
      doc:
        "Whether or not the attribute can be provided as input, or will be shown when extensions work with the resource (i.e won't appear in a web api)."
    ],
    update_default: [
      type: {:or, [{:mfa_or_fun, 0}, :literal]},
      doc: "A value to be set on all updates, unless a value is being provided already."
    ],
    filterable?: [
      type: {:or, [:boolean, {:in, [:simple_equality]}]},
      default: true,
      doc: "Whether or not the attribute can be referenced in filters."
    ],
    default: [
      type: {:or, [{:mfa_or_fun, 0}, :literal]},
      doc: "A value to be set on all creates, unless a value is being provided already."
    ],
    description: [
      type: :string,
      doc: "An optional description for the attribute."
    ],
    match_other_defaults?: [
      type: :boolean,
      default: false,
      doc: """
      Ensures that other attributes that use the same "lazy" default (a function or an mfa), use the same default value.
      Has no effect unless `default` is a zero argument function.
      For example, create and update timestamps use this option, and have the same lazy function `&DateTime.utc_now/0`, so they
      get the same value, instead of having slightly different timestamps.
      """
    ]
  ]

  @create_timestamp_schema @schema
                           |> OptionsHelpers.set_default!(:writable?, false)
                           |> OptionsHelpers.set_default!(:private?, true)
                           |> OptionsHelpers.set_default!(:default, &DateTime.utc_now/0)
                           |> OptionsHelpers.set_default!(:match_other_defaults?, true)
                           |> OptionsHelpers.set_default!(:type, Ash.Type.UtcDatetimeUsec)
                           |> OptionsHelpers.set_default!(:allow_nil?, false)

  @update_timestamp_schema @schema
                           |> OptionsHelpers.set_default!(:writable?, false)
                           |> OptionsHelpers.set_default!(:private?, true)
                           |> OptionsHelpers.set_default!(:match_other_defaults?, true)
                           |> OptionsHelpers.set_default!(:default, &DateTime.utc_now/0)
                           |> OptionsHelpers.set_default!(
                             :update_default,
                             &DateTime.utc_now/0
                           )
                           |> OptionsHelpers.set_default!(:type, Ash.Type.UtcDatetimeUsec)
                           |> OptionsHelpers.set_default!(:allow_nil?, false)

  @uuid_primary_key_schema @schema
                           |> OptionsHelpers.set_default!(:writable?, false)
                           |> OptionsHelpers.set_default!(:default, &Ash.UUID.generate/0)
                           |> OptionsHelpers.set_default!(:primary_key?, true)
                           |> OptionsHelpers.set_default!(:type, :uuid)
                           |> Keyword.delete(:allow_nil?)

  @integer_primary_key_schema @schema
                              |> OptionsHelpers.set_default!(:writable?, false)
                              |> OptionsHelpers.set_default!(:primary_key?, true)
                              |> OptionsHelpers.set_default!(:generated?, true)
                              |> OptionsHelpers.set_default!(:type, :integer)
                              |> Keyword.delete(:allow_nil?)

  @doc false
  def attribute_schema, do: @schema
  def create_timestamp_schema, do: @create_timestamp_schema
  def update_timestamp_schema, do: @update_timestamp_schema
  def uuid_primary_key_schema, do: @uuid_primary_key_schema
  def integer_primary_key_schema, do: @integer_primary_key_schema
end
