module Components.Integrations exposing (Model, Msg, init, update, view)

import Components.Integrations.GCalendar as GCalendar
import Components.Page exposing (pageWithTabs)
import Html exposing (..)
import Html.App as Html
import Ports exposing (pushPath)
import Routes exposing (Sitemap(..), IntegrationsSitemap(..))
import Types exposing (User, IntegrationStates)


type Msg
    = RouteTo Sitemap
    | ToGCalendar GCalendar.Msg


type alias Context =
    { fullRoute : Sitemap
    , subRoute : Maybe IntegrationsSitemap
    , currentUser : User
    , integrationStates : IntegrationStates
    }


type alias Model =
    { fullRoute : Sitemap
    , subRoute : IntegrationsSitemap
    , currentUser : User
    , integrationStates : IntegrationStates
    , gCalendar : GCalendar.Model
    }


init : Context -> ( Model, Cmd Msg )
init { fullRoute, subRoute, currentUser, integrationStates } =
    let
        ( gCalendar, gCalendarFx ) =
            GCalendar.init integrationStates.gCalendar
    in
        { fullRoute = fullRoute
        , subRoute = (Maybe.withDefault (GCalendarR ()) subRoute)
        , currentUser = currentUser
        , integrationStates = integrationStates
        , gCalendar = gCalendar
        }
            ! [ Cmd.map ToGCalendar gCalendarFx ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RouteTo route ->
            ( model, pushPath (Routes.route route) )

        ToGCalendar msg ->
            let
                ( gCalendar, fx ) =
                    GCalendar.update msg model.gCalendar
            in
                { model | gCalendar = gCalendar } ! [ Cmd.map ToGCalendar fx ]


view : Model -> Html Msg
view ({ fullRoute, subRoute, gCalendar } as model) =
    pageWithTabs RouteTo
        fullRoute
        [ ( IntegrationsR (GCalendarR ()), "Google Calendar" )
        ]
        [ case subRoute of
            GCalendarR () ->
                GCalendar.view gCalendar
                    |> Html.map ToGCalendar
        ]
