port module Main exposing (..)

import Html.App as Html
import Model exposing (Message(..), Flags)
import Timestamp exposing (Timestamp, Timezone)
import Update exposing (init, update)
import View exposing (view)


main : Program Flags
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions =
            \_ ->
                Sub.batch
                    [ timestamps Tick
                    , timezones TimezoneChanged
                    , path PathChanged
                    ]
        }


port path : (String -> msg) -> Sub msg


port timestamps : (Timestamp -> msg) -> Sub msg


port timezones : (Timezone -> msg) -> Sub msg
