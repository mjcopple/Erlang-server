-module(monitor).

-export([main/3, details/3, add/3, update/3, update_all/3]).
-export([start/0, all_known_nodes/0, get_time/0]).

-define(Headers, "Content-Type: text/html\r\n\r\n").
-define(Top, "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\"><html><head><meta http-equiv=\"Content-type\" content=\"text/html;charset=UTF-8\"><link href=\"../../../styles.css\" rel=\"stylesheet\" type=\"text/css\"><title>Erlang cluster</title></head><body>").
-define(Bottom, "</body></html>").

-define(BackToMain, "<p><a href=main>Back to Main</a>").
-define(AddNode, "<p><form name=add action=add method=get><p>Add a node: <input type=text name=node><input type=submit value=Add></form>").

-define(Time, "<div class=date>", Time, "<br>", get_time(), "</div>").
-define(KnownNodes, "<p>", NumberNodes, " known nodes.", KnownNodes).

start() ->
 inets:start(),
 inets:start(httpd, [
   {modules, [mod_alias, mod_auth, mod_esi, mod_actions, mod_cgi, mod_dir, mod_get, mod_head, mod_log, mod_disk_log]},
   {port,8081},
   {server_name,"monitor"},
   {server_root,"log"},
   {document_root,"www"},
   {erl_script_alias, {"/erl", [monitor]}},
   {error_log, "error.log"},
   {security_log, "security.log"},
   {transfer_log, "transfer.log"},
   {mime_types,[{"html","text/html"}, {"css","text/css"}, {"js","application/x-javascript"}]}]).

main(SessionID, _Env, _Input) ->
	CurrentNode = atom_to_list(node()),
	IPAddress = ip:get_ip_address_string(),
	UpdateAll = "<p><a href=update_all>Update All Nodes</a>",
	Time = get_time(),
	{KnownNodes, NumberNodes} = all_known_nodes(),
	mod_esi:deliver(SessionID, [?Headers, ?Top, ?Time, "<p>", CurrentNode, ?KnownNodes, ?AddNode, "<p>", IPAddress, UpdateAll, ?Bottom]).

details(SessionID, _Env, Input) ->
	Node = list_to_atom(Input),
	Response = case net_adm:ping(Node) of
		pong ->	
			Pid = spawn(Node, node_details, run, []),
			Pid ! {self(), ip_address},
			Pid ! {self(), known_nodes},
			Pid ! {self(), time},
			Pid ! {self(), quit},
			erlang:yield(),
			receive {Pid, ip_address, IPAddress} -> done end,
			receive {Pid, known_nodes, {KnownNodes, NumberNodes}} -> done end,
			receive {Pid, time, Time} -> done end,
			[?Time, "<p>", Input, " is running.<p>", IPAddress, ?KnownNodes, "<p><a href=\"update?", Input, "\">Update Code</a>"];
		pang -> ["<p>", Input, " is not running."]
	end,
	mod_esi:deliver(SessionID, [?Headers, ?Top, Response, ?BackToMain, ?Bottom]).

add(SessionID, Env, "node=" ++ Input) ->
	Node = yaws_api:url_decode(Input),
	case net_adm:ping(list_to_atom(Node)) of
        pong -> main(SessionID, Env, Input);
        pang -> mod_esi:deliver(SessionID, [?Headers, ?Top, "Can't connect to node ", Node, ?BackToMain, ?Bottom])
    end;
add(SessionID, _Env, Input) ->	
	Node = yaws_api:url_decode(Input),
	mod_esi:deliver(SessionID, [?Headers, ?Top, "What? ", Node, ?BackToMain, ?Bottom]).

update(SessionID, Env, Input) ->
	Node = list_to_atom(Input),
	spawn(Node, update, update, []),
	details(SessionID, Env, Input).

get_time() ->
	{{Year, Month, Day}, {Hour, Minute, Second}} = calendar:universal_time(),
	{_, _, SubSecond} = erlang:now(),
	io_lib:format("~4.10.0b-~2.10.0b-~2.10.0b ~2.10.0b:~2.10.0b:~2.10.0b.~3.10.0b", [Year, Month, Day, Hour, Minute, Second, SubSecond div 1000]).

update_all(SessionID, Env, Input) ->
	update:update_all(),
	monitor:main(SessionID, Env, Input).

all_known_nodes() ->
	Nodes = nodes(known),
	KnownNodes = parseKnownNodes(Nodes),
	NumberNodes = io_lib:write(length(Nodes), 10),
	{KnownNodes, NumberNodes}.

parseKnownNodes(KnownNodes) ->
	parseKnownNodes(KnownNodes, "</table>").
parseKnownNodes([], Acc) ->
	["<table>" | Acc];
parseKnownNodes([Head | Tail], Acc) ->
	String = atom_to_list(Head),
	parseKnownNodes(Tail, ["<tr><td><a href=\"details?", String, "\">", String, "</a>", "</td></tr>", Acc]).
