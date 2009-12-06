-module(ip).

-export([get_ip_address_string/0]).

get_ip_address_string() ->
	{ok, IPAddress} = inet:getif(),
	io_lib:write(filter_ip_address(IPAddress)).

filter_ip_address(IPAddress) ->
	filter_ip_address(IPAddress, []).

filter_ip_address([], Acc) ->
	Acc;
filter_ip_address([{{127,0,0,1},{0,0,0,0},{255,0,0,0}} | Tail], Acc) ->
	%Don't include the loopback address.
	filter_ip_address(Tail, Acc);
filter_ip_address([Head | Tail], Acc) ->
{IP, _Broadcast, _Mask} = Head,
	filter_ip_address(Tail, [IP | Acc]).
