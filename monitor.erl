-module(monitor).
-export([start/0, main/3, details/3]).

-define(Headers, "Content-Type: text/html\r\n\r\n").
-define(Top, "<html><body>").
-define(Bottom, "</body></html>").

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
	KnownNodes = nodes(known),
	mod_esi:deliver(SessionID, [?Headers, ?Top, "Known nodes:", parseKnownNodes(KnownNodes), "<br><form name=add action=add method=get>Add a node: <input type=text name=node><input type=submit value=Add></form>", ?Bottom]).

details(SessionID, _Env, Input) ->
	Response = case net_adm:ping(list_to_atom(Input)) of
		pong -> "Running";
		pang -> "Stopped"
	end,
	mod_esi:deliver(SessionID, [?Headers, ?Top, "Details for: ", Input, " ", Response, "<br><a href=main>Back to Main</a>", ?Bottom]).

parseKnownNodes(KnownNodes) ->
	parseKnownNodes(KnownNodes, "</table>").
parseKnownNodes([], Acc) ->
	["<table>" | Acc];
parseKnownNodes([Head | Tail], Acc) ->
	String = atom_to_list(Head),
	parseKnownNodes(Tail, ["<tr><a href=details?", String, ">", String, "</a>", Acc, "</tr>"]).
