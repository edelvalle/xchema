defmodule Xchema do
  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)

      def validate(data) do
        Xchema.validate __MODULE__, data
      end
    end
  end

  defmacro field(name, attrs) do
    quote do
      def unquote(name)(), do: unquote(attrs)
    end
  end

  def validate(schema, data) do
    result = schema.module_info(:functions)
    |> Keyword.keys()
    |> Enum.uniq()
    |> Enum.reject(&(&1 in [:__info__, :module_info, :validate]))
    |> Enum.map(fn (member) -> {member, apply(schema, member, [])} end)
    |> Enum.reject(fn ({_name, info}) -> info[:read_only] end)
    |> Enum.map(fn ({name, info}) -> validate_field(name, info, data) end)
    |> Enum.map(&validate_in_schema(schema, &1))
    |> Enum.group_by(
        fn ({ok?, _name, _value}) -> ok? end,
        fn ({_ok?, name, value}) -> {name, value} end
      )

    ok? = if Map.has_key?(result, :error) do :error else :ok end
    {ok?, Map.new(result[:error] || result[:ok])}
  end

  def validate_field(name, info, data) do
    value = data[Atom.to_string(name)] || data[name] || :empty
    type = info[:type]
    required = Keyword.get info, :required, true
    allow_nil = Keyword.get info, :allow_nil, not required
    allow_blank = Keyword.get info, :allow_blank, false
    default = info[:default] || :empty

    {ok?, value} = if required and value == :empty do
      {:error, "This field is required"}
    else
      # transform :empty -> nil, and set default value
      value = if value == :empty or is_nil(value) do
        cond do
          is_function(default) -> default.()
          default != :empty -> default
          value == :empty -> nil
          true -> value
        end
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

  # def serialize(schema, obj) do
  # end

end
