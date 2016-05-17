module Components.Settings exposing (Model, Msg, init, update, view)

import Components.Page exposing (pageWithTabs)
import Html exposing (..)
import Ports exposing (pushPath)
import Routes exposing (Sitemap(..), SettingsMap(..))


type Msg
    = Submit
    | RouteTo Sitemap


type alias Model =
    { fullRoute : Sitemap
    , subRoute : SettingsMap
    }


init : Sitemap -> SettingsMap -> Model
init =
    Model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Submit ->
            model ! []

        RouteTo route ->
            model ! [ pushPath (Routes.route route) ]


view : Model -> Html Msg
view ({ fullRoute, subRoute } as model) =
    pageWithTabs RouteTo
        fullRoute
        [ ( SettingsR (TeamR ()), "Team" )
        , ( SettingsR (BillingR ()), "Billing" )
        ]
        []
