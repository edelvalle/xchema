
defmodule DSLPerson do
  use Xchema

  field :name, [
    type: :string,
    required: false,
    allow_blank: true,
    default: "Alex",
  ]

  def name(:valid?, value) do
    if value == "invalid name" do
      {:error, "This name is invalid"}
    else
      {:ok, value}
    end
  end

  field :age, [
      type: :integer,
  ]
end

defmodule Xchema.Test.DSL do
  use ExUnit.Case, async: true

  test "A valid person works" do
    result = DSLPerson.validate %{name: "Juan", age: 3}
    assert result == [{:ok, :age, 3}, {:ok, :name, "Juan"}]
  end

  test "A person with an invalid name is recognized" do
    result = DSLPerson.validate %{name: "invalid name", age: 3}
    assert result == [{:ok, :age, 3}, {:error, :name, "This name is invalid"}]
  end

  test "When name is not provided default value is used" do
    result = DSLPerson.validate %{age: 3}
    assert result == [{:ok, :age, 3}, {:ok, :name, "Alex"}]
  end

end



