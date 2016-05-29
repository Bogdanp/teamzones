module Main exposing (main)

import AnimationFrame
import Model exposing (Model, Msg(..), Flags)
import Navigation
import Ports exposing (timestamps, timezones, notifications)
import Routes exposing (parsePath)
import Update exposing (init, update, urlUpdate)
import View exposing (view)


main : Program Flags
main =
    Navigation.programWithFlags (Navigation.makeParser parsePath)
        { init = init
        , view = view
        , update = update
        , urlUpdate = urlUpdate
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ timestamps Tick
        , timezones TimezoneChanged
        , notifications Notified
        , AnimationFrame.times UpdateSidebar
        ]
