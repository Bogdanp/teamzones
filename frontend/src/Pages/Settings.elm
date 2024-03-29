module Pages.Settings exposing (Model, Msg, init, update, view)

import Components.Page exposing (pageWithTabs)
import Html exposing (..)
import Html.App as Html
import Pages.Settings.Billing as Billing
import Pages.Settings.Team as Team
import Routes exposing (Sitemap(..), SettingsSitemap(..))
import Types exposing (User)
import Util exposing ((?>))


type Msg
    = RouteTo Sitemap
    | ToTeam Team.Msg
    | ToBilling Billing.Msg


type alias Context pmsg =
    { deleteUser : String -> pmsg
    , fullRoute : Sitemap
    , subRoute : Maybe SettingsSitemap
    , currentUser : User
    , teamMembers : List User
    }


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

        subRoute' =
            subRoute ?> TeamR ()
    in
        { fullRoute = fullRoute
        , subRoute = subRoute'
        , teamMembers = teamMembers
        , team = team
        , billing = billing
        }
            ! [ if subRoute' == BillingR () then
                    Cmd.map ToBilling billingFx
                else
                    Cmd.none
              ]


update : Msg -> Model pmsg -> ( Model pmsg, Cmd Msg, Maybe pmsg )
update msg ({ team, billing } as model) =
    case msg of
        RouteTo route ->
            ( model, Routes.navigateTo route, Nothing )

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
