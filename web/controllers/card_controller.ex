defmodule PlanIt.CardController do
  alias PlanIt.Repo
  alias PlanIt.Card

  import Ecto.Query
  import Ecto.Changeset

  use PlanIt.Web, :controller

  # GET - get all cards on a specific day of a specific trip
  def index(conn, %{"trip_id" => trip_id, "day" => day_num}) do
    if trip_id == nil or day_num == nil do
      json put_status(conn, 400), "bad parameters"
    end

    cards = (from c in Card,
          where: c.trip_id == ^trip_id and c.day_number == ^day_num,
          select: c,
          order_by: [asc: :start_time]
    ) |> Repo.all

    json conn, cards
  end

  # GET - get all cards on a specific trip
  def index(conn,%{"trip_id" => trip_id} = params) do
    if trip_id == nil do
      json put_status(conn, 400), "bad parameters"
    end

    cards = (from c in Card,
          where: c.trip_id == ^trip_id,
          select: c,
          order_by: [asc: :start_time]
    ) |> Repo.all

    json conn, cards
  end

  # GET - bad params
  def index(conn, _params) do
    error = "no resource available"
    json put_status(conn, 400), error
  end

  #POST update/create with a list of cards
  ## the new card will have an ID of 0
  def create(conn, %{"trip_id" => trip_id, "_json" => cards} = params) do
    new_card = Enum.find(cards, fn(c) -> Map.get(c, "id") == 0 end)
    IO.inspect(new_card)
    {status, new_card_changeset} = Repo.insert(Card.changeset(%Card{}, new_card))

    if status == :error do
      error = "error: #{inspect new_card_changeset.errors}"
      json put_status(conn, 400), error
    end

    existing_cards = Enum.filter(cards, fn(c) -> Map.get(c, "id") != 0 end)

    repo_messages = Enum.map(existing_cards, fn(c) ->
      Repo.get(Card, Map.get(c, "id"))
      |> Card.changeset(params)
      |> Repo.update()
    end)

    changesets = Enum.map(repo_messages, fn(c) ->
      case c do
        {:ok, changeset} -> changeset
        _ -> nil
      end
    end) |> Enum.filter(fn(i) -> i end)

    messages = Enum.map(repo_messages, fn(c) ->
      case c do
        {:error, message} -> message
        _ -> nil
      end
    end) |> Enum.filter(fn(i) -> i end)

    return_package = changesets ++ [new_card_changeset]

    json conn, return_package
  end

  # POST - insert new cards
  def create(conn, %{"_json" => cards } = params) do
    #    ecto_cards = Enum.map(cards, fn(c) ->
    #      %{
    #      type: Map.get(c, "type"),
    #      name: Map.get(c, "name"),
    #      city: Map.get(c, "city"),
    #      country: Map.get(c, "country"),
    #      address: Map.get(c, "address"),
    #      lat: Map.get(c, "lat"),
    #      long: Map.get(c, "long"),
    #      start_time: Map.get(c, "start_time") |> Ecto.DateTime.cast!,
    #      end_time: Map.get(c, "end_time") |> Ecto.DateTime.cast!,
    #      day_number: Map.get(c, "day_number"),
    #      trip_id: Map.get(c, "trip_id"),
    #
    #      travel_type: Map.get(c, "travel_type"),
    #      travel_duration: Map.get(c, "travel_duration")|> Ecto.Time.cast!,
    #
    #      inserted_at: Ecto.DateTime.utc,
    #      updated_at: Ecto.DateTime.utc
    #      }
    #    end)

    #try do
    #   Repo.insert_all(Card, ecto_cards)
    #catch
    #  _, _ -> json put_status(conn, 400), "BAD"
    #end

    return_items = Enum.map(cards, fn(c) ->
      {status, changeset} = Card.changeset(%Card{}, c) |> Repo.insert()
    end)

    changesets = Enum.map(return_items, fn(c) ->
      case c do
        {:ok, changeset} -> changeset
        _ ->
      end
    end)
    |> Enum.filter(fn(i) -> i end)

    messages = Enum.map(return_items, fn(c) ->
      case c do
        {:error, message} -> message
         _ -> nil
      end
    end)
    |> Enum.filter(fn(i) -> i end)

    json conn, changesets
  end



  # PUT - update an existing card
  def update(conn, %{"id" => card_id} = params) do
    card = Repo.get(Card, card_id)
    changeset = Card.changeset(card, params)

    {message, changeset} = Repo.update(changeset)

    if message == :error do
      error = "error: #{inspect changeset.errors}"
      json put_status(conn, 400), error
    end

    json conn, "ok"
  end

  # DELETE - delete a card
  def delete(conn, %{"id" => card_id} = params) do
    card = Repo.get!(Card, card_id)
    case Repo.delete card do
      {:ok, struct} -> json conn, "ok"
      {:error, changeset} -> json put_status(conn, 400), "failed to delete"
    end
  end
end
