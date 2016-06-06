module Pages.Settings.Team exposing (Model, Msg, init, update, view)

import Api exposing (Error, Response)
import Api.Team as TeamApi exposing (deleteUser)
import Components.ConfirmationButton as CB
import Components.Notifications exposing (apiError)
import Dict exposing (Dict)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Routes exposing (Sitemap(..))
import Task
import Types exposing (AnchorTo, User, UserRole(..))
import Util exposing ((=>))


type alias Context pmsg =
    { deleteUser : String -> pmsg
    , currentUser : User
    , teamMembers : List User
    }


type Msg
    = RouteTo Sitemap
    | ToDeleteButton String CB.Msg
    | DeleteError String Error
    | DeleteSuccess String (Response String)


type alias Model pmsg =
    { rootDeleteUser : String -> pmsg
    , currentUser : User
    , teamMembers : List User
    , deleteMemberButtons : Dict String CB.Model
    }


init : Context pmsg -> Model pmsg
init { deleteUser, currentUser, teamMembers } =
    let
        deleteMemberButtons =
            List.map (\u -> ( u.email, CB.init "Delete" )) teamMembers
                |> Dict.fromList
    in
        { rootDeleteUser = deleteUser
        , currentUser = currentUser
        , teamMembers = teamMembers
        , deleteMemberButtons = deleteMemberButtons
        }


update : Msg -> Model pmsg -> ( Model pmsg, Cmd Msg, Maybe pmsg )
update msg ({ rootDeleteUser, teamMembers, deleteMemberButtons } as model) =
    let
        updateButtons email msg =
            Dict.map
                (\e b ->
                    if e == email then
                        CB.update msg b
                    else
                        b
                )
                deleteMemberButtons
    in
        case msg of
            RouteTo route ->
                ( model, Routes.navigateTo route, Nothing )

            ToDeleteButton email ((CB.ToParent (CB.Confirm)) as msg) ->
                ( { model | deleteMemberButtons = updateButtons email msg }
                , Task.perform (DeleteError email) (DeleteSuccess email) (deleteUser email)
                , Nothing
                )

            ToDeleteButton email msg ->
                ( { model | deleteMemberButtons = updateButtons email msg }, Cmd.none, Nothing )

            DeleteError email errors ->
                ( model, Cmd.batch (apiError errors), Nothing )

            DeleteSuccess email _ ->
                let
                    members =
                        List.filter ((/=) email << .email) teamMembers

                    buttons =
                        Dict.remove email deleteMemberButtons
                in
                    ( { model | teamMembers = members, deleteMemberButtons = buttons }, Cmd.none, Just (rootDeleteUser email) )


view : Model pmsg -> Html Msg
view { currentUser, teamMembers, deleteMemberButtons } =
    let
        members =
            List.sortBy (.role >> toString) teamMembers
    in
        div []
            [ br [] []
            , table [ class "table" ]
                [ thead []
                    [ tr []
                        [ td [ style [ "width" => "30%" ] ] [ text "Name" ]
                        , td [ style [ "width" => "30%" ] ] [ text "Email" ]
                        , td [ style [ "width" => "20%" ] ] [ text "Role" ]
                        , td [ style [ "width" => "20%" ] ] []
                        ]
                    ]
                , tbody [] (List.map (memberRow currentUser deleteMemberButtons) members)
                ]
            ]


memberRow : User -> Dict String CB.Model -> User -> Html Msg
memberRow currentUser buttons { fullName, email, role } =
    let
        deleteButton =
            case Dict.get email buttons of
                Just button ->
                    CB.view button
                        |> Html.map (ToDeleteButton email)

                Nothing ->
                    Debug.crash "impossible"
    in
        tr []
            [ td [] [ anchorTo (ProfileR email) [] [ text fullName ] ]
            , td [] [ text email ]
            , td [] [ text (toString role) ]
            , td []
                [ if role /= Main && currentUser.email /= email then
                    deleteButton
                  else
                    text ""
                ]
            ]


anchorTo : AnchorTo Msg
anchorTo =
    Util.anchorTo RouteTo
