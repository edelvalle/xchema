
defmodule EnergyConsumtion do
  use Xchema

  field :year, type: :integer, source: [:date, :year]
  field :consumption, type: :array
  field :average, type: :float

  def average(:get, obj) do
    consumption_length = length(obj[:consumption])
    if consumption_length > 0 do
      Enum.sum(obj[:consumption]) / length(obj[:consumption])
    else
      0
    end
  end

end


defmodule Xchema.Test.Serialization do
  use ExUnit.Case, async: true

  test "A consumption object van be serialized" do
    result = EnergyConsumtion.serialize %{
      date: %{year: 2017},
      consumption: [2, 5, 10]
    }
    assert result == %{
      year: 2017,
      consumption: [2, 5, 10],
      average: 5.666666666666667,
    }
  end

end
