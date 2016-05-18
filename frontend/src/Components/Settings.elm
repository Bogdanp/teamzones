module Components.Settings exposing (Model, Msg, init, update, view)

import Components.Page exposing (pageWithTabs)
import Components.Settings.Billing as Billing
import Components.Settings.Team as Team
import Html exposing (..)
import Html.App as Html
import Ports exposing (pushPath)
import Routes exposing (Sitemap(..), SettingsSitemap(..))
import Types exposing (User)


type alias Context pmsg =
    { deleteUser : String -> pmsg
    , fullRoute : Sitemap
    , subRoute : Maybe SettingsSitemap
    , currentUser : User
    , teamMembers : List User
    }


type Msg
    = RouteTo Sitemap
    | ToTeam Team.Msg


type alias Model pmsg =
    { fullRoute : Sitemap
    , subRoute : SettingsSitemap
    , teamMembers : List User
    , team : Team.Model pmsg
    }


init : Context pmsg -> Model pmsg
init { deleteUser, fullRoute, subRoute, currentUser, teamMembers } =
    let
        team =
            Team.init
                { deleteUser = deleteUser
                , currentUser = currentUser
                , teamMembers = teamMembers
                }
    in
        Model fullRoute (Maybe.withDefault (TeamR ()) subRoute) teamMembers team


update : Msg -> Model pmsg -> ( Model pmsg, Cmd Msg, Maybe pmsg )
update msg ({ team } as model) =
    case msg of
        RouteTo route ->
            ( model, pushPath (Routes.route route), Nothing )

        ToTeam msg ->
            let
                ( team, fx, pmsg ) =
                    Team.update msg team
            in
                ( { model | team = team }, Cmd.map ToTeam fx, pmsg )


view : Model pmsg -> Html Msg
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
                Team.view team
                    |> Html.map ToTeam
        ]
