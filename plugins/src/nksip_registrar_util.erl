%% -------------------------------------------------------------------
%%
%% Copyright (c) 2015 Carlos Gonzalez Florido.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

%% @doc NkSIP Registrar Server Plugin Utilities (only for internal storage)
-module(nksip_registrar_util).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-include("nksip_registrar.hrl").

-export([get_all/0, clear/0, print_all/0]).


%% ===================================================================
%% Utilities available only using internal store
%% ===================================================================


% @private Get all current registrations. Use it with care.
-spec get_all() ->
    [{nksip:srv_id(), nksip:aor(), [#reg_contact{}]}].

get_all() ->
    [
        {SrvId, AOR, nklib_store:get({nksip_registrar, SrvId, AOR}, [])}
        || {SrvId, AOR} <- all()
    ].


%% @private
print_all() ->
    Now = nklib_util:timestamp(),
    Print = fun({SrvId, {Scheme, User, Domain}, Regs}) ->
        io:format("\n --- ~p --- ~p:~s@~s ---\n", [SrvId:name(), Scheme, User, Domain]),
        lists:foreach(
            fun(#reg_contact{contact=Contact, expire=Expire, q=Q}) ->
                io:format("    ~s, ~p, ~p\n", [nklib_unparse:uri(Contact), Expire-Now, Q])
            end, Regs)
    end,
    lists:foreach(Print, get_all()),
    io:format("\n\n").


%% @private Clear all stored records for all Services, only with buil-in database
%% Returns the number of deleted items.
-spec clear() -> 
    integer().

clear() ->
    Fun = fun(SrvId, AOR, _Val, Acc) ->
        nklib_store:del({nksip_registrar, SrvId, AOR}),
        Acc+1
    end,
    fold(Fun, 0).


%% @private
all() -> 
    fold(fun(SrvId, AOR, _Value, Acc) -> [{SrvId, AOR}|Acc] end, []).


%% @private
fold(Fun, Acc0) when is_function(Fun, 4) ->
    FoldFun = fun(Key, Value, Acc) ->
        case Key of
            {nksip_registrar, SrvId, AOR} -> Fun(SrvId, AOR, Value, Acc);
            _ -> Acc
        end
    end,
    nklib_store:fold(FoldFun, Acc0).


