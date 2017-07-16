defmodule Xchema do
  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)

      def validate(data) do
        Xchema.validate __MODULE__, data
      end

      def serialize(data) do
        Xchema.serialize __MODULE__, data
      end
    end
  end

  defmacro field(name, attrs) do
    quote do
      def unquote(name)(), do: unquote(attrs)
    end
  end

  @fields_to_exclude [
    :__info__,
    :module_info,
    :valid?,
    :validate,
    :serialize,
  ]

  def functions(schema) do
    schema.module_info(:functions)
    |> Keyword.keys()
    |> Enum.uniq()
  end

  def fields(schema) do
    schema
    |> functions()
    |> Enum.reject(&(&1 in @fields_to_exclude))
    |> Enum.map(fn (name) -> {name, field_info(schema, name)} end)
  end

  def field_info(schema, name) do
    info = apply(schema, name, [])

    default = info[:default]
    default = if is_function(default) do
      default
    else
      fn () -> default end
    end

    required = Keyword.get info, :required, true

    [
      type: info[:type],
      required: required,
      allow_nil: Keyword.get(info, :allow_nil, not required),
      allow_blank: info[:allow_blank] || false,
      default: default,
      source: info[:source] || [name],
      read_only: info[:read_only] || false,
      write_only: info[:write_only] || false,
    ]
  end

  def validate(schema, data) do
    result = fields(schema)
    |> Enum.reject(fn ({_name, info}) -> info[:read_only] end)
    |> Enum.map(fn ({name, info}) -> validate_field(name, info, data) end)
    |> Enum.map(&validate_in_schema(schema, &1))
    |> Enum.group_by(
        fn ({ok?, _name, _value}) -> ok? end,
        fn ({_ok?, name, value}) -> {name, value} end
      )

    ok? = if Map.has_key?(result, :error) do :error else :ok end
    almost_ready = Map.new(result[:error] || result[:ok])

    if ok? == :ok and :valid? in functions(schema) do
      schema.valid? almost_ready
    else
      {ok?, almost_ready}
    end
  end

  def serialize(schema, obj) do
    fields(schema)
    |> Enum.reject(fn ({_name, info}) -> info[:write_only] end)
    |> Enum.map(fn ({name, info}) -> {name, get_value(schema, obj, info[:source])} end)
    |> Map.new()
  end

  def get_value(schema, obj, attrs) do
    try do
      apply schema, List.first(attrs), [:get, obj]
    rescue
      UndefinedFunctionError -> get_value(obj, attrs)
    end
  end
  def get_value(obj, attrs \\ []) do
    if attrs == [] || obj == :empty do
      obj
    else
      [attr | tail] = attrs
      value = Map.get(obj, attr, obj[Atom.to_string(attr)])
      get_value(value, tail)
    end
  end

  def validate_field(name, info, data) do
    value = data[Atom.to_string(name)] || data[name] || :empty

    type = info[:type]
    required = info[:required]
    allow_nil = info[:allow_nil]
    allow_blank = info[:allow_blank]
    default = info[:default]

    {ok?, value} = if required and value == :empty do
      {:error, "This field is required"}
    else
      # if value is nill or empty use the default value
      value = if value == :empty or is_nil(value) do
        default.()
      else
        value
      end

      # simple validation
      cond do
        not allow_nil and is_nil(value) ->
          {:error, "This field can't be nil"}

        not allow_blank and blank?(value) ->
          {:error, "This field can't be empty"}

        not valid_type?(type, value) ->
          {:error, "Value '#{inspect(value)}' is not a valid #{type}"}

        true -> {:ok, value}
      end
    end

    {ok?, name, value}
  end

  def validate_in_schema(schema, {ok?, name, value}) do
    {ok?, value} = case ok? do
      :ok ->
        try do
          apply schema, name, [:valid?, value]
        rescue
          UndefinedFunctionError -> {:ok, value}
        end
      :error -> {:error, value}
    end

    {ok?, name, value}
  end

  def valid_type?(type, value) do
    is_nil(value) or case type do
      :string -> is_bitstring(value)
      :integer -> is_integer(value)
      :float -> is_float(value)
      :number -> is_number(value)
      :boolean -> is_boolean(value)
      :array -> is_list(value)
      :object -> is_map(value)
      _ -> false
    end
  end

  def blank?(value) do
    if is_bitstring(value) do
      String.trim(value) == ""
    else
      value == [] or value == 0
    end
  end

end
