-module(node_details).

-export([run/0]).

run() ->
	receive
		{From, ip_address} ->
			From ! {self(), ip_address, ip:get_ip_address_string()},
			run();
		{From, known_nodes} ->
			From ! {self(), known_nodes, monitor:all_known_nodes()},
			run();
		{_From, quit} ->
			done
	end.
