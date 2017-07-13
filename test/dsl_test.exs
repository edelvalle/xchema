
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

  field :age, type: :integer

  field :is_married, type: :boolean, required: false
end

defmodule Xchema.Test.DSL do
  use ExUnit.Case, async: true

  test "A valid person works" do
    result = DSLPerson.validate %{name: "Juan", age: 3}
    assert result == {:ok, %{age: 3, name: "Juan", is_married: nil}}
  end

  test "A person with an invalid name is recognized" do
    result = DSLPerson.validate %{name: "invalid name", age: 3}
    assert result == {:error, %{name: "This name is invalid"}}
  end

  test "When name is not provided default value is used" do
    result = DSLPerson.validate %{age: 3}
    assert result == {:ok, %{age: 3, name: "Alex", is_married: nil}}
  end

  test "When a boolean is passed to boolean field it works" do
    result = DSLPerson.validate %{age: 3, is_married: true}
    assert result == {:ok, %{age: 3, name: "Alex", is_married: true}}
  end

  test "When a int is passed in a boolean field it complains" do
    result = DSLPerson.validate %{age: 3, is_married: 1}
    assert result == {:error, %{is_married: "Value '1' is not a valid boolean"}}
  end

end



