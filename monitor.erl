-module(monitor).
-export([start/0, main/3, details/3, add/3]).

-define(Headers, "Content-Type: text/html\r\n\r\n").
-define(Top, "<html><body>").
-define(Bottom, "</body></html>").

-define(BackToMain, "<br><a href=main>Back to Main</a>").
-define(AddNode, "<br><form name=add action=add method=get>Add a node: <input type=text name=node><input type=submit value=Add></form>").

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
	CurrentNode = node(),
	IPAddress = ip:get_ip_address_string(),
	mod_esi:deliver(SessionID, [?Headers, ?Top, "Known nodes:", allKnownNodes(), ?AddNode, IPAddress, ?Bottom]).

details(SessionID, _Env, Input) ->
	Node = list_to_atom(Input),
	Response = case net_adm:ping(Node) of
		pong ->	
			Pid = spawn(Node, ip, run, []),
			Pid ! {self(), ip_address},
			Pid ! {self(), known_nodes},
			erlang:yield(),
			receive {Pid, ip_address, IPAddress} -> done end,
			receive {Pid, known_nodes, Nodes} -> done end,
			%IPAddress = ip:get_ip_address_string(),
			"Running<br>" ++ IPAddress ++ "<br>Known Nodes: " ++ Nodes;
		pang -> "Stopped"
	end,
	mod_esi:deliver(SessionID, [?Headers, ?Top, "Details for: ", Input, " ", Response, ?BackToMain, ?Bottom]).

add(SessionID, Env, [$n, $o, $d, $e, $= | Input]) ->
	case net_adm:ping(list_to_atom(yaws_api:url_decode(Input))) of
        pong -> main(SessionID, Env, Input);
        pang -> mod_esi:deliver(SessionID, [?Headers, ?Top, "Can't connect to node ", Input, ?BackToMain, ?Bottom])
    end;
add(SessionID, _Env, Input) ->	
	mod_esi:deliver(SessionID, [?Headers, ?Top, "What? ", Input, ?BackToMain, ?Bottom]).

allKnownNodes() ->
	Nodes = nodes(known),
	parseKnownNodes(Nodes).

parseKnownNodes(KnownNodes) ->
	parseKnownNodes(KnownNodes, "</table>").
parseKnownNodes([], Acc) ->
	["<table>" | Acc];
parseKnownNodes([Head | Tail], Acc) ->
	String = atom_to_list(Head),
	parseKnownNodes(Tail, ["<tr><a href=details?", String, ">", String, "</a>", Acc, "</tr>"]).
