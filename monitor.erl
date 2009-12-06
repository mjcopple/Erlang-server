-module(monitor).

-export([main/3, details/3, add/3, update/3, update_all/3]).
-export([start/0, all_known_nodes/0, get_time/0]).

-define(Headers, "Content-Type: text/html\r\n\r\n").
-define(Top, "<html><head><link href=\"../../../styles.css\" rel=\"stylesheet\" type=\"text/css\"><title>Erlang cluster</title></head><body>").
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
	CurrentNode = atom_to_list(node()),
	IPAddress = ip:get_ip_address_string(),
	UpdateAll = "<br><a href=update_all>Update All Nodes</a>",
	Time = get_time(),
	mod_esi:deliver(SessionID, [?Headers, ?Top, CurrentNode, Time, "<br>Known nodes:", all_known_nodes(), ?AddNode, IPAddress, UpdateAll, ?Bottom]).

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
			receive {Pid, known_nodes, Nodes} -> done end,
			receive {Pid, time, Time} -> done end,
			"Running<br>" ++ IPAddress ++ "<br>" ++ Time ++ "<br>Known Nodes: " ++ Nodes;
		pang -> "Stopped"
	end,
	mod_esi:deliver(SessionID, [?Headers, ?Top, "Details for: ", Input, " ", Response, "<br><a href=update?", Input, ">Update Code</a>", ?BackToMain, ?Bottom]).

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
	io_lib:write(erlang:localtime(), 100).

update_all(SessionID, Env, Input) ->
	update:update_all(),
	main(SessionID, Env, Input).

all_known_nodes() ->
	Nodes = nodes(known),
	parseKnownNodes(Nodes).

parseKnownNodes(KnownNodes) ->
	parseKnownNodes(KnownNodes, "</table>").
parseKnownNodes([], Acc) ->
	["<table>" | Acc];
parseKnownNodes([Head | Tail], Acc) ->
	String = atom_to_list(Head),
	parseKnownNodes(Tail, ["<tr><td><a href=details?", String, ">", String, "</a>", Acc, "</td></tr>"]).
