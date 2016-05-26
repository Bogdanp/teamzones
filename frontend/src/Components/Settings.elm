module Components.Settings exposing (Model, Msg, init, update, view)

import Components.Page exposing (pageWithTabs)
import Components.Settings.Billing as Billing
import Components.Settings.Team as Team
import Html exposing (..)
import Html.App as Html
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
    | ToBilling Billing.Msg


type alias Model pmsg =
    { fullRoute : Sitemap
    , subRoute : SettingsSitemap
    , teamMembers : List User
    , team : Team.Model pmsg
    , billing : Billing.Model
    }


init : Context pmsg -> ( Model pmsg, Cmd Msg )
init { deleteUser, fullRoute, subRoute, currentUser, teamMembers } =
    let
        team =
            Team.init
                { deleteUser = deleteUser
                , currentUser = currentUser
                , teamMembers = teamMembers
                }

        ( billing, billingFx ) =
            Billing.init
    in
        { fullRoute = fullRoute
        , subRoute = (Maybe.withDefault (TeamR ()) subRoute)
        , teamMembers = teamMembers
        , team = team
        , billing = billing
        }
            ! [ Cmd.map ToBilling billingFx ]


update : Msg -> Model pmsg -> ( Model pmsg, Cmd Msg, Maybe pmsg )
update msg ({ team, billing } as model) =
    case msg of
        RouteTo route ->
            ( model, Routes.push route, Nothing )

        ToTeam msg ->
            let
                ( team, fx, pmsg ) =
                    Team.update msg team
            in
                ( { model | team = team }, Cmd.map ToTeam fx, pmsg )

        ToBilling msg ->
            let
                ( billing, fx ) =
                    Billing.update msg billing
            in
                ( { model | billing = billing }, Cmd.map ToBilling fx, Nothing )


view : Model pmsg -> Html Msg
view ({ fullRoute, subRoute, team, billing } as model) =
    pageWithTabs RouteTo
        fullRoute
        [ ( SettingsR (TeamR ()), "Team" )
        , ( SettingsR (BillingR ()), "Billing" )
        ]
        [ case subRoute of
            BillingR () ->
                Billing.view billing
                    |> Html.map ToBilling

            TeamR () ->
                Team.view team
                    |> Html.map ToTeam
        ]
