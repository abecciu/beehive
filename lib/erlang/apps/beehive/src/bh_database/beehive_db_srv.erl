%%% beehive_db_srv.erl
%% @author Ari Lerner <arilerner@mac.com>
%% @copyright 05/28/10 Ari Lerner <arilerner@mac.com>
%% @doc Database server
-module (beehive_db_srv).

-behaviour(gen_server).

%% API
-export([
  start_link/0, start_link/1, start_link/2,
  read/2,
  write/3,
  delete/2,
  all/1,
  run/1,
  status/0
]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, 
    handle_info/2, terminate/2, code_change/3]).

-record(state, {
  adapter
}).

-define(SERVER, ?MODULE).

%%====================================================================
%% API
%%====================================================================
% Get the status of the db
status() -> gen_server:call(?SERVER, {status}).
read(Table, Key) -> gen_server:call(?SERVER, {read, Table, Key}).
write(Table, Key, Proplist) -> gen_server:call(?SERVER, {write, Table, Key, Proplist}).
delete(Table, Key) -> gen_server:call(?SERVER, {delete, Table, Key}).
all(Table) -> gen_server:call(?SERVER, {all, Table}).
run(Fun) -> gen_server:call(?SERVER, {run, Fun}).

%%--------------------------------------------------------------------
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}
%% Description: Starts the server
%%--------------------------------------------------------------------
start_link() -> start_link(mnesia, []).
start_link(DbAdapter) -> start_link(DbAdapter, []).
start_link(DbAdapter, Nodes) when is_atom(DbAdapter) -> 
  gen_server:start_link({local, ?SERVER}, ?MODULE, [erlang:atom_to_list(DbAdapter), Nodes], []);
start_link(DbAdapter, Nodes) -> gen_server:start_link({local, ?SERVER}, ?MODULE, [DbAdapter, Nodes], []).

%%====================================================================
%% gen_server callbacks
%%====================================================================

%%--------------------------------------------------------------------
%% Function: init(Args) -> {ok, State} |
%%                         {ok, State, Timeout} |
%%                         ignore               |
%%                         {stop, Reason}
%% Description: Initiates the server
%%--------------------------------------------------------------------
init([DbAdapterName, Nodes]) ->
  DbAdapter = erlang:list_to_atom(lists:flatten(["db_", DbAdapterName, "_adapter"])),
  
  case erlang:module_loaded(DbAdapter) of
    true -> ok;
    false -> code:load_file(DbAdapter)
  end,

  ok = try_to_call(DbAdapter, start, [Nodes]),
  {ok, #state{
    adapter = DbAdapter
  }}.
%%--------------------------------------------------------------------
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}
%% Description: Handling call messages
%%--------------------------------------------------------------------
handle_call({write, Table, Key, Proplist}, _From, #state{adapter = Adapter} = State) ->
  {reply, try_to_call(Adapter, write, [Table, Key, Proplist]), State};
handle_call({read, Table, Key}, _From, #state{adapter = Adapter} = State) ->
  {reply, try_to_call(Adapter, read, [Table, Key]), State};
handle_call({delete, Table, Key}, _From, #state{adapter = Adapter} = State) ->
  {reply, try_to_call(Adapter, delete, [Table, Key]), State};
handle_call({status}, _From, #state{adapter = Adapter} = State) ->
  {reply, try_to_call(Adapter, status, []), State};
handle_call({all, Table}, _From, #state{adapter = Adapter} = State) ->
  {reply, try_to_call(Adapter, all, [Table]), State};
handle_call({run, Fun}, _From, #state{adapter = Adapter} = State) ->
  {reply, try_to_call(Adapter, run, [Fun]), State};
handle_call(_Request, _From, State) ->
  Reply = ok,
  {reply, Reply, State}.

%%--------------------------------------------------------------------
%% Function: handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}
%% Description: Handling cast messages
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
  ok.

%%--------------------------------------------------------------------
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------
%%-------------------------------------------------------------------
%% @spec () ->    {ok, Value}
%% @doc The directory for the database
%% @end
%%-------------------------------------------------------------------
% Super utility
try_to_call(M, F, A) ->
  case erlang:function_exported(M,F,erlang:length(A)) of
    true -> apply(M,F,A);
    false -> not_found
  end.