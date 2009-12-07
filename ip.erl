-module(ip).

-export([get_ip_address_string/0]).

get_ip_address_string() ->
	{ok, IPAddress} = inet:getif(),
	filter_ip_address(IPAddress).

filter_ip_address(IPAddress) ->
	filter_ip_address(IPAddress, []).

filter_ip_address([], Acc) ->
	Acc;
filter_ip_address([{{127,0,0,1}, _Broadcast, _Mask} | Tail], Acc) ->
	%Don't include the loopback address.
	filter_ip_address(Tail, Acc);
filter_ip_address([Head | Tail], Acc) ->
	{{Oct1, Oct2, Oct3, Oct4}, _Broadcast, _Mask} = Head,
	IPString = io_lib:format("~b.~b.~b.~b ", [Oct1, Oct2, Oct3, Oct4]),
	filter_ip_address(Tail, IPString ++ Acc).
