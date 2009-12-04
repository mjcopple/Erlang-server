-module(ip).

-export([run/0, get_ip_address_string/0]).

run() ->
	receive
		{From, ip_address} ->
			From ! get_ip_address_string()
	end.

get_ip_address_string() ->
	{ok, IPAddress} = inet:getif(),
	io_lib:write(filter_ip_address(IPAddress)).

filter_ip_address(IPAddress) ->
	filter_ip_address(IPAddress, []).

filter_ip_address([], Acc) ->
	Acc;
filter_ip_address([Head | Tail], Acc) ->
{IP, _Broadcast, _Mask} = Head,
	filter_ip_address(Tail, [IP | Acc]).