
defmodule Person do
  def name do
    [
      type: :string,
      required: false,
      allow_blank: true,
      default: "Alex",
    ]
  end
  def name(:valid?, value) do
    if value == "invalid name" do
      {:error, "This name is invalid"}
    else
      {:ok, value}
    end
  end

  def age do
    [
      type: :integer,
    ]
  end
end

defmodule Xchema.Test do
  use ExUnit.Case, async: true

  test "A valid person works" do
    result = Xchema.validate Person, %{name: "Juan", age: 3}
    assert result == [{:ok, :age, 3}, {:ok, :name, "Juan"}]
  end

  test "A person with an invalid name is recognized" do
    result = Xchema.validate Person, %{name: "invalid name", age: 3}
    assert result == [{:ok, :age, 3}, {:error, :name, "This name is invalid"}]
  end

  test "When name is not provided default value is used" do
    result = Xchema.validate Person, %{age: 3}
    assert result == [{:ok, :age, 3}, {:ok, :name, "Alex"}]
  end

end



