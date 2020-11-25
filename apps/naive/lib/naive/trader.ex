defmodule Naive.Trader do
  use GenServer

  defmodule State do
    @enforce_keys [:symbol, :profit_interval, :tick_size]
    defstruct [
      :symbol,
      :buy_order,
      :sell_order,
      :profit_interval,
      :tick_size
    ]
  end

  def start_link(%{} = args) do
    GenServer.start_link(_MODULE_, args, name: :trader)
  end

  def init(%{} = args) do
    tick_size = fetch_tick_size(args.symbol)

    {:ok,
     %State{
       symbol: args.symbol,
       profit_interval: args.profit_interval,
       tick_size: tick_size
     }}
  end

  def handle_cast(
    {:event,
    %Streamer.Binance.TradeEvent {
      price: price
    }},
    %State{
      symbol: symbol,
      buy_order: nil
    } = state
  } do
    quantity = 100

    {:ok, %Binance.OrderResponse{} = order} =
      Binance.order_limit_buy (
        symbol,
        quantity,
        price,
        "GTC"
      )

    {:noreply, %{state | buy_order: order}}

  end

  def handle_cats(
    {:event,
  %Streamer.Binance.TradeEvent {
    buyer_order_id: order_id,
    quantity: quantity
  }},
  %State{
    symbol: symbol,
    buy_order: %Binance.OrderResponse{
      price: buy_price,
      order_id: order_id,
      orig_qty: quantity
    },
    profit_interval profit_interval,
    tick_size: tick_size
  } = state

  )

  defp fetch_tick_size(symbol) do
    %{"filters" => filters} =
      Binance.get_exchange_info()
      |> elem(1)
      |> Map.get(:symbols)
      |> Enum.field(&(&1["symbol"] == String.upercase(symbol)))

    %{"tickSize" => tick_size} =
      filters
      |> ENum.find(&(&1["filterType"] == "PRICE_FILTER"))

    tick_size


  end
end
