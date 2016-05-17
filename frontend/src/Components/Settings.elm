module Components.Settings exposing (Model, Msg, init, update, view)

import Components.Page exposing (pageWithTabs)
import Components.Settings.Billing as Billing
import Components.Settings.Team as Team
import Html exposing (..)
import Html.App as Html
import Html.Lazy exposing (lazy)
import Ports exposing (pushPath)
import Routes exposing (Sitemap(..), SettingsMap(..))
import Types exposing (User)


type Msg
    = RouteTo Sitemap
    | ToTeam Team.Msg


type alias Model =
    { fullRoute : Sitemap
    , subRoute : SettingsMap
    , teamMembers : List User
    , team : Team.Model
    }


init : Sitemap -> SettingsMap -> List User -> Model
init fullRoute subRoute teamMembers =
    Model fullRoute subRoute teamMembers (Team.init teamMembers)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ team } as model) =
    case msg of
        RouteTo route ->
            model ! [ pushPath (Routes.route route) ]

        ToTeam msg ->
            let
                ( team, fx ) =
                    Team.update msg team
            in
                { model | team = team } ! [ Cmd.map ToTeam fx ]


view : Model -> Html Msg
view ({ fullRoute, subRoute, team } as model) =
    pageWithTabs RouteTo
        fullRoute
        [ ( SettingsR (TeamR ()), "Team" )
        , ( SettingsR (BillingR ()), "Billing" )
        ]
        [ case subRoute of
            BillingR () ->
                Billing.view

            TeamR () ->
                lazy Team.view team
                    |> Html.map ToTeam
        ]
