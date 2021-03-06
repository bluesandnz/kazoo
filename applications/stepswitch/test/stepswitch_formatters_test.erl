%%%-------------------------------------------------------------------
%%% @copyright (C) 2014-2015, 2600Hz
%%% @doc
%%%
%%% @end
%%% @contributors
%%%   James Aimonetti
%%%-------------------------------------------------------------------
-module(stepswitch_formatters_test).

-include_lib("eunit/include/eunit.hrl").

-define(OFFNET_REQ, wh_json:from_list([{<<"Custom-SIP-Headers">>
                                        ,wh_json:from_list([{<<"Diversions">>
                                                             ,[<<"sip:14158867900@1.2.3.4;counter=1">>]
                                                            }
                                                           ])
                                       }
                                       ,{<<"Invite-Format">>, <<"npan">>}
                                      ])).

-define(ROUTE_REQ, wh_json:from_list([{<<"To">>, <<"12345556789@2600hz.com">>}
                                      ,{<<"From">>, <<"4158867900@2600hz.com">>}
                                      ,{<<"Request">>, <<"+12345556789@2600hz.com">>}
                                      ,{<<"Call-ID">>,<<"352401574@10.26.0.158">>}
                                      ,{<<"Caller-ID-Number">>, <<"+14158867900">>}
                                      ,{<<"Custom-SIP-Headers">>
                                        ,wh_json:from_list([{<<"X-AUTH-IP">>,<<"10.26.0.158">>}])
                                       }
                                     ])).

regex_inbound_test_() ->
    Formatter = wh_json:from_list([{<<"to">>
                                    ,[wh_json:from_list([{<<"regex">>, <<"^\\+?1?(\\d{10})$">>}
                                                         ,{<<"prefix">>, <<"+1">>}
                                                         ,{<<"direction">>, <<"inbound">>}
                                                        ])
                                     ]
                                   }
                                   ,{<<"from">>
                                     ,[wh_json:from_list([{<<"regex">>, <<"^\\+?1?(\\d{10})$">>}
                                                          ,{<<"prefix">>, <<"+1">>}
                                                          ,{<<"direction">>, <<"inbound">>}
                                                         ])
                                      ]
                                    }
                                   ,{<<"request">>
                                     ,[wh_json:from_list([{<<"regex">>, <<"^\\+?1?(\\d{10})$">>}
                                                          ,{<<"prefix">>, <<"+1">>}
                                                          ,{<<"direction">>, <<"inbound">>}
                                                         ])
                                      ]
                                    }
                                   ,{<<"caller_id_number">>
                                     ,[wh_json:from_list([{<<"regex">>, <<"^\\+?1?(\\d{10})$">>}
                                                          ,{<<"direction">>, <<"inbound">>}
                                                         ])
                                      ]
                                    }
                                  ]),

    Route = stepswitch_formatters:apply(?ROUTE_REQ, Formatter, 'inbound'),

    [?_assertEqual(<<"+12345556789@2600hz.com">>, wh_json:get_value(<<"To">>, Route))
     ,?_assertEqual(<<"+12345556789@2600hz.com">>, wh_json:get_value(<<"Request">>, Route))
     ,?_assertEqual(<<"+14158867900@2600hz.com">>, wh_json:get_value(<<"From">>, Route))
     ,?_assertEqual(<<"4158867900">>, wh_json:get_value(<<"Caller-ID-Number">>, Route))
    ].

strip_inbound_test_() ->
    Formatter = wh_json:from_list([{<<"to">>
                                    ,[wh_json:from_list([{<<"regex">>, <<"^\\+?1?(\\d{10})$">>}
                                                         ,{<<"prefix">>, <<"+1">>}
                                                         ,{<<"direction">>, <<"inbound">>}
                                                         ,{<<"strip">>, 'true'}
                                                        ])
                                     ]
                                   }
                                   ,{<<"caller_id_number">>
                                     ,[wh_json:from_list([{<<"regex">>, <<"^\\+?1?(\\d{10})$">>}
                                                          ,{<<"direction">>, <<"inbound">>}
                                                          ,{<<"strip">>, 'true'}
                                                         ])
                                      ]
                                    }
                                  ]),

    Route = stepswitch_formatters:apply(?ROUTE_REQ, Formatter, 'inbound'),

    [?_assertEqual('undefined', wh_json:get_value(<<"To">>, Route))
     ,?_assertEqual('undefined', wh_json:get_value(<<"Caller-ID-Number">>, Route))
    ].

diversion_match_invite_test_() ->
    Formatter = wh_json:from_list([{<<"diversions">>
                                    ,[wh_json:from_list([{<<"match_invite_format">>, 'true'}])]
                                   }
                                  ]),
    Bridge = stepswitch_formatters:apply(?OFFNET_REQ, Formatter, 'outbound'),

    [?_assertEqual(<<"sip:4158867900@1.2.3.4">>
                   ,kzsip_diversion:address(
                      wh_json:get_value([<<"Custom-SIP-Headers">>, <<"Diversions">>], Bridge)
                     )
                  )
    ].

diversion_strip_test_() ->
    Formatter = wh_json:from_list([{<<"diversions">>
                                    ,[wh_json:from_list([{<<"strip">>, 'true'}])]
                                   }
                                  ]),
    Bridge = stepswitch_formatters:apply(?OFFNET_REQ, Formatter, 'outbound'),

    [?_assertEqual('undefined'
                   ,wh_json:get_value([<<"Custom-SIP-Headers">>, <<"Diversions">>], Bridge)
                  )
    ].

replace_value_test_() ->
    Replace = wh_util:rand_hex_binary(10),

    Formatter = wh_json:from_list([{<<"from">>
                                    ,[wh_json:from_list([{<<"value">>, Replace}])]
                                   }
                                   ,{<<"caller_id_number">>
                                    ,[wh_json:from_list([{<<"value">>, Replace}])]
                                    }
                                  ]),

    Bridge = stepswitch_formatters:apply(?ROUTE_REQ, Formatter, 'outbound'),
    [?_assertEqual(<<Replace/binary, "@2600hz.com">>
                   ,wh_json:get_value(<<"From">>, Bridge)
                  )
     ,?_assertEqual(Replace, wh_json:get_value(<<"Caller-ID-Number">>, Bridge))
    ].
