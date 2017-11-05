setup:
	mix deps.get
	mix ecto.create
	mix ecto.migrate

drop:
	mix ecto.drop

create:
	mix ecto.create
	mix ecto.migrate

migrate:
	mix ecto.migrate

start:
	mix phx.server
