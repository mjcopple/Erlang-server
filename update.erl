-module(update).

-export([update/0, update_all/0]).

update() ->
	update(update),
	update:update(node_details),
	update(ip),
	update(monitor).

update(Node) ->
	code:soft_purge(Node),
	code:load_file(Node).

update_all() ->
	Nodes = nodes(known),
	update_all(Nodes).

update_all([]) -> done;
update_all([Head | Tail]) ->
	update(Head),
	update_all(Tail).
