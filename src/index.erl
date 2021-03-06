%% -*- mode: nitrogen -*-
%% vim: ts=4 sw=4 et
-module (index).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").
-include_lib("bitmessage/include/bm.hrl").
-include("records.hrl").
-include("db.hrl").
-include("protokol.hrl").

main() -> common:main().

title() -> "Welcome to RISE".

icon() -> "<i class='icon-globe icon-2x' style='margin-top:-5px;'></i>".

buttons(main) -> % {{{1
    #list{class="nav nav-pills", style="display:inline-block;", numbered=false,
          body=[
                #listitem{body=[
                                common:render_filters()
                               ]},
                #listitem{body=[
                                #link{id=archive, body="<i class='icon-list-alt'></i> Archive", postback={show_archive, true}}
                               ]},
                #listitem{body=[
                                common:settings_menu()
                               ]},
                #listitem{body=[
                                common:render_help()
                               ]}
               ]}.

left() -> % {{{1
    left(false).

left(Archive) -> % {{{1
    case db:get_updates(Archive) of 
        {ok, none} ->
            render_left([]);
        {ok, Updates} ->
            render_left(Updates)
    end.

render_left(Updates) -> % {{{1
    SortedUpdates = sugar:sort_by_timestamp(Updates),
    GroupedUpdates = group_updates(SortedUpdates),
    Render = [ #update_preview{id=Id,
                               icon=Enc,
                               from=From,
                               to=To,
                               age="Age",
                               subject=Subject,
                               text=Text,
                               flag=true,
                               archive=(Status == archive)} || 
               #message{hash=Id,
                        from=From,
                        to=To,
                        subject=Subject,
                        text=Text,
                        enc=Enc,
                        status=Status} <- GroupedUpdates],
    #panel{id=left,class="span4 scrollable", body=Render}.

group_updates(List) ->
    group_updates(List, []).

group_updates([], Acc) -> Acc;
group_updates([U | Rest], Acc0) ->
    Acc = case subject_exists_in_updates(U#message.subject, Acc0) of
        true -> add_participants(U, Acc0);
        false -> Acc0 ++ [U]
    end,
    group_updates(Rest, Acc).

add_participants(Update, Messages) ->
    lists:map(fun
                  (M) when M#message.subject==Update#message.subject ->
                    M#message{
                      from=maybe_wrap_list(M#message.from) ++ [Update#message.from],
                      to=maybe_wrap_list(M#message.to) ++ [Update#message.to]
                    };
                  (M) -> M
              end, Messages).
                     
maybe_wrap_list(AddressList) when is_list(AddressList) ->
    AddressList;
maybe_wrap_list(Address) when is_binary(Address) ->
    [Address].

subject_exists_in_updates(Subject, Messages) ->
    case [X || X <- Messages, X#message.subject==Subject] of
        [] -> false;
        [X] -> true
    end.

body() -> % {{{1
    body(false).

body(Archive) -> % {{{1
    #panel{id=body,
           class="span8 scrollable",
           body=case wf:session(current_subject) of
                    undefined ->
                        [];
                    Subject ->
                        render_body(Subject, Archive)
                end
          }.

render_body(Subject, Archive) -> % {{{1
    wf:session(current_subject, Subject),
    {ok, Updates} = db:get_updates_by_subject(Subject, Archive),
    Type = (hd(Updates))#message.enc,
    Icon = element_update_preview:render_icon(Type),
    [
     #h1{body=[Icon," ",wf:html_encode(Subject)]},
     [
      #update_element{collapse=true,
                      from=From,
                      to=To,
                      text=Text,
                      uid=Id,
                      subject=Subject,
                      enc=Enc,
                      status=Status} || #message{hash=Id,
                                                 enc=Enc,
                                                 to=To,
                                                 subject=Subject,
                                                 from=From,
                                                 text=Text,
                                                 status=Status} <- sugar:sort_by_timestamp(Updates)
     ] 
    ].

replace_left() -> % {{{1
    replace_left(left()).

replace_left(Body) -> % {{{1
    wf:wire("scrolltop_temp = objs('left').scrollTop()"),
    wf:replace(left, Body),
    wf:wire("objs('left').scrollTop(scrolltop_temp)").

event({selected, Id, Subject, Archive}) -> % {{{1
    wf:session(current_subject, Subject),
    wf:session(current_update_id, Id),
    replace_left(left(Archive)),
    wf:update(body, render_body(Subject, Archive)),
    wf:wire("$(\".update-preview\").has(\"input[type=checkbox]:checked\").addClass(\"related-message\");"),
    wf:wire("$(\".update-preview\").has(\"input[type=checkbox]:not(:checked)\").removeClass(\"related-message\");");

event({archive, E, Rec}) -> % {{{1
    {ok, #message{subject=Subject}} = db:archive(#message{hash=Rec}),
    replace_left(),
    wf:update(body, render_body(Subject, false));

event({show_archive, true}) -> % {{{1
    wf:replace(archive, #link{id=archive, body="<i class='icon-list-alt'></i> Actual", postback={show_archive, false}}),
    {ok, Updates} = db:get_updates(true),
    #db_contact{id=My} = wf:user(),
    {ok, Tasks} = db:get_tasks(true),
    replace_left(render_left(Updates)),
    wf:replace(body, body(true));

event({show_archive, false}) -> % {{{1
    wf:replace(archive, #link{id=archive, body="<i class='icon-list-alt'></i> Archive", postback={show_archive, true}}),
    replace_left(),
    wf:replace(body, body());

event(Click) -> % {{{1
    io:format("Event ~p in ~p~n", [Click, ?MODULE]).

incoming() -> % {{{1
    replace_left().
