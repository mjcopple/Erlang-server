-module(update).

-export([update/0]).

update() ->
	update(update),
	update:update(node_details),
	update(ip),
	update(monitor).

update(Node) ->
	code:soft_purge(Node),
	code:load_file(Node).
